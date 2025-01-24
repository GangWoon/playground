import Foundation
import UIKit.UIApplication

public protocol Requestable<ID>: Sendable {
  associatedtype ID: Hashable, Sendable, CustomStringConvertible
  associatedtype Response: MemorySizeProvider
  func execute(id: ID) async throws -> Response
}

public final class Cache<Request: Requestable>: Sendable {
  let request: Request
  let configuration: Configuration
  
  let storage: LockIsolated<Storage<Box<RequestState>>>
  
  private let memoryWarningTask = LockIsolated<Task<Void, Never>?>(nil)
  private let expireTask = LockIsolated<Task<Void, Never>?>(nil)
  
  public init(
    request: Request,
    configuration: Configuration = Configuration()
  ) {
    self.request = request
    self.configuration = configuration
    self.storage = .init(.init(totoalCostLimit: configuration.limit.cost))
    
    self.memoryWarningTask.setValue(buildMemoryWarningTask())
    self.expireTask.setValue(buildExpireTask())
  }
  
  private func buildMemoryWarningTask() -> Task<Void, Never> {
    Task {
      let stream = NotificationCenter.default
        .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
        .values
      for await _ in stream {
        storage.withValue {
          $0.removeAllObjects()
        }
      }
    }
  }
  
  private func buildExpireTask() -> Task<Void, Never> {
    Task {
      let stream = Timer
        .publish(
          every: configuration.cleanupInterval,
          on: .main,
          in: .common
        )
        .autoconnect()
        .values
      for await _ in stream {
        self.removeExpired()
      }
    }
  }
  
  private func removeExpired() {
    storage.withValue { cache in
      for (key, box) in cache where box.isExpired {
        box.loadingState?.task.cancel()
        cache.removeObject(forKey: key)
      }
    }
  }
  
  public func execute(
    _ id: Request.ID,
    expiration: StorageExpiration? = nil
  ) async throws -> Request.Response {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        storage.withValue { cache in
          let key = id.description
          
          let box: Box<RequestState>
          if let object = cache.object(forKey: key) {
            box = object
          } else {
            guard !Task.isCancelled else {
              continuation.resume(throwing: CancellationError())
              return
            }
            let expiration = expiration ?? configuration.expiration
            let task = buildTask(id, expiration: expiration)
            box = Box<RequestState>(
              key: key,
              value: .loading(.init(task: task, continuations: [continuation])),
              expiration: expiration
            )
            cache.setObject(box, forKey: key)
            return
          }
          
          switch box.value {
          case .response(let response):
            continuation.resume(returning: response)
            
          case .loading(var state):
            guard !Task.isCancelled else {
              continuation.resume(throwing: CancellationError())
              state.task.cancel()
              return
            }
            state.continuations.append(continuation)
            box.value.loadingState = state
          }
          
          if !box.isExpired {
            box.extendExpiration()
          }
        }
      }
    } onCancel: {
      let task = storage.withValue { cache in
        cache.object(forKey: id.description)?.loadingState?.task
      }
      task?.cancel()
    }
  }
  
  private func buildTask(
    _ id: Request.ID,
    expiration: StorageExpiration
  ) -> Task<Void, Never> {
    Task {
      do {
        let response = try await self.request.execute(id: id)
        let continuations: [Continuation] = try storage.withValue { cache  in
          let key = id.description
          guard
            let loadingState = cache.object(forKey: key)?.loadingState
          else { return [] }
          let box = Box<RequestState>(
            key: key,
            value: .response(response),
            expiration: expiration
          )
          cache.setObject(
            box,
            forKey: key,
            cost: try response.estimatedMemory.cost
          )
          return loadingState.continuations
        }
        try Task.checkCancellation()
        for continuation in continuations {
          continuation.resume(returning: response)
          await Task.yield()
        }
      } catch {
        self.cancel(for: id, error: error)
      }
    }
  }
  
  public func cancel(for id: Request.ID, error: any Error) {
    let continuations: [Continuation] = self.storage.withValue { cache in
      let key = id.description
      let continuations = cache
        .object(forKey: key)?
        .loadingState?
        .continuations
      ?? cache.removedContinuations[key]
      ?? []
      
      cache.removeObject(forKey: key)
      cache.removedContinuations[key] = nil
      
      return continuations
    }
    
    Task {
      for continuation in continuations {
        continuation.resume(throwing: error)
        await Task.yield()
      }
    }
  }
}

extension Cache {
  public struct Configuration: Sendable {
    var limit: Measurement<UnitInformationStorage>
    var expiration: StorageExpiration
    var cleanupInterval: TimeInterval
    
    public init(
      limit: Measurement<UnitInformationStorage> = .default,
      expiration: StorageExpiration = .seconds(300),
      cleanupInterval: TimeInterval = 120
    ) {
      self.limit = limit
      self.expiration = expiration
      self.cleanupInterval = cleanupInterval
    }
  }
  
  typealias Continuation = CheckedContinuation<Request.Response, any Error>
  enum RequestState: Sendable {
    case response(Request.Response)
    
    struct LoadingState: Sendable {
      let task: Task<Void, Never>
      var continuations: [Continuation]
    }
    var loadingState: LoadingState? {
      get {
        guard
          case .loading(let state) = self else
        { return nil }
        return state
      }
      set {
        guard let newValue else { return }
        self = .loading(newValue)
      }
    }
    case loading(LoadingState)
  }
  
  @dynamicMemberLookup
  final class Box<Value> {
    var key: String
    var value: Value
    let expiration: StorageExpiration
    private(set) var estimatedExpiration: Date
    
    var isExpired: Bool {
      Date().timeIntervalSince(estimatedExpiration) <= 0
    }
    
    init(
      key: String,
      value: Value,
      expiration: StorageExpiration
    ) {
      self.key = key
      self.value = value
      self.expiration = expiration
      self.estimatedExpiration = expiration.estimatedExpirationSinceNow
    }
    
    func extendExpiration(_ extendingExpiration: ExpirationExtending = .cacheTime) {
      switch extendingExpiration {
      case .none: break
      case .cacheTime:
        self.estimatedExpiration = expiration.estimatedExpirationSinceNow
      case .expirationTime(let expiration):
        self.estimatedExpiration = expiration.estimatedExpirationSinceNow
      }
    }
    
    public subscript<Member>(dynamicMember keyPath: KeyPath<Value, Member>) -> Member {
      self.value[keyPath: keyPath]
    }
  }
}

extension Cache {
  final class Storage<Value: AnyObject>: NSObject, NSCacheDelegate {
    let cache = NSCache<NSString, Value>()
    var keys = Set<String>()
    var removedContinuations: [String: [Continuation]] = [:]
    
    init(totoalCostLimit: Int) {
      self.cache.totalCostLimit = totoalCostLimit
      super.init()
      self.cache.delegate = self
    }
    
    func object(forKey key: String) -> Value? {
      cache.object(forKey: key as NSString)
    }
    
    func setObject(_ obj: Value, forKey key: String, cost: Int = 0) {
      cache.setObject(obj, forKey: key as NSString, cost: cost)
      keys.insert(key)
    }
    
    func removeObject(forKey key: String) {
      cache.removeObject(forKey: key as NSString)
      keys.remove(key)
    }
    
    func removeAllObjects() {
      cache.removeAllObjects()
      keys.removeAll()
    }
    
    func cache(
      _ cache: NSCache<AnyObject, AnyObject>,
      willEvictObject obj: Any
    ) {
      guard
        let box = obj as? Box<RequestState>,
        let loadingState = box.loadingState
      else { return }
      removedContinuations[box.key] = loadingState.continuations
      keys.remove(box.key)
    }
  }
}

extension Cache.Storage: Sequence {
  func makeIterator() -> AnyIterator<(String, Value)> {
    var iterator = keys.makeIterator()
    return AnyIterator {
      while let key = iterator.next() {
        if let value = self.cache.object(forKey: key as NSString) {
          return (key, value)
        }
      }
      return nil
    }
  }
}

extension Measurement<UnitInformationStorage> {
  public static let `default`: Self = {
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    let limit = totalMemory / 4
    let costLimit = (limit > UInt64(Int.max)) ? UInt64(Int.max) : limit
    return .init(value: Double(costLimit), unit: .bytes)
  }()
}

extension Cache.RequestState: MemorySizeProvider {
  var estimatedMemory: Measurement<UnitInformationStorage> {
    get throws {
      switch self {
      case .response(let response):
        return try response.estimatedMemory
        
        //TODO: 배열 자체도 크기를 갖기 때문에 추후에 수정하면 좋을 거 같음.
      case .loading:
        return .init(value: .zero, unit: .bytes)
      }
    }
  }
}

private extension LockIsolated where Value == Set<String> {
  @discardableResult
  func insert(_ element: String) -> (inserted: Bool, memberAfterInsert: String) {
    withValue { $0.insert(element) }
  }
  
  @discardableResult
  func remove(_ element: String) -> String? {
    withValue { $0.remove(element) }
  }
  
  func removeAll() {
    withValue { $0.removeAll() }
  }
}


public protocol MemorySizeProvider: Sendable {
  var estimatedMemory: Measurement<UnitInformationStorage> { get throws }
}

extension Measurement where UnitType == UnitInformationStorage {
  var cost: Int {
    Int(converted(to: .bytes).value)
  }
}

public enum StorageExpiration: Sendable {
  var estimatedExpirationSinceNow: Date {
    switch self {
    case .never: return .distantFuture
    case .seconds(let seconds): return Date().addingTimeInterval(seconds)
    case .expired: return .distantPast
    }
  }
  
  var isExpired: Bool {
    timeInterval <= 0
  }
  
  var timeInterval: TimeInterval {
    switch self {
    case .never: return .infinity
    case .seconds(let seconds): return seconds
    case .expired:return -.infinity
    }
  }
  
  case never
  case seconds(TimeInterval)
  case expired
}

public enum ExpirationExtending: Sendable {
  case none
  case cacheTime
  case expirationTime(expiration: StorageExpiration)
}

