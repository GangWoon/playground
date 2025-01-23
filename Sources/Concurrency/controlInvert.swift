import Foundation

public protocol Requestable<ID>: Sendable {
  associatedtype ID: Hashable, Sendable, CustomStringConvertible
  associatedtype Response: MemorySizeProvider
  func execute(id: ID) async throws -> Response
}

public final class Cache<Request: Requestable>: Sendable {
  let request: Request
  let configuration: Configuration
  
  private let storage: LockIsolated<NSCache<NSString, Box<RequestState>>>
  private let keys = LockIsolated<Set<String>>([])
  
  public init(
    request: Request,
    configuration: Configuration
  ) {
    self.request = request
    self.configuration = configuration
    let cache = NSCache<NSString, Box<RequestState>>()
    cache.totalCostLimit = configuration.limit.cost
    self.storage = .init(cache)
  }
  
  public func execute(_ id: Request.ID) async throws -> Request.Response {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        storage.withValue { cache in
          let key = id.description as NSString
          let box = cache.object(forKey: key)
          switch box?.value {
          case .response(let response):
            continuation.resume(returning: response)
            
          case .loading(var state):
            guard !Task.isCancelled else {
              continuation.resume(throwing: CancellationError())
              state.task.cancel()
              return
            }
            state.continuations.append(continuation)
            /// 해당 부분에서 `loadingState`를 업데이트하지만, Box 내부 수정은 외부에서 관리되지 않으므로,
            /// 반드시 `withValue` 안에서 원자적으로 처리되어야 함.
            box?.value.loadingState = state
            
          case .none:
            guard !Task.isCancelled else {
              continuation.resume(throwing: CancellationError())
              return
            }
            let initalTask = buildInitialTask(id)
            let box = Box<RequestState>(
              .loading(.init(task: initalTask, continuations: [continuation])),
              expiration: .never
            )
            cache.setObject(box, forKey: key)
          }
        }
      }
    } onCancel: {
      let task = storage.withValue { cache in
        cache.object(forKey: id.description as NSString)?.loadingState?.task
      }
      task?.cancel()
    }
  }
  
  private func buildInitialTask(_ id: Request.ID) -> Task<Void, Never> {
    Task {
      do {
        let response = try await self.request.execute(id: id)
        
        let continuations: [Continuation] = try storage.withValue { cache  in
          let key = id.description as NSString
          guard
            let loadingState = cache.object(forKey: key)?.loadingState
          else { return [] }
          let box = Box<RequestState>(.response(response), expiration: .never)
          cache.setObject(
            box,
            forKey: key,
            cost: try response.estimatedMemory.cost
          )
          return loadingState.continuations
        }
        
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
      let key = id.description as NSString
      let continuations = cache
        .object(forKey: key)?
        .loadingState?
        .continuations ?? []
      cache.removeObject(forKey: key)
      
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
}

extension Cache {
  public struct Configuration: Sendable {
    var limit: Measurement<UnitInformationStorage>
    var expiration: StorageExpiration
    var cleanupInterval: TimeInterval
    
    public init(
      limit: Measurement<UnitInformationStorage> = .init(value: 300, unit: .bytes),
      expiration: StorageExpiration = .seconds(300),
      cleanupInterval: TimeInterval = 120000000
    ) {
      self.limit = limit
      self.expiration = expiration
      self.cleanupInterval = cleanupInterval
    }
  }
  
  @dynamicMemberLookup
  final class Box<Value> {
    var value: Value
    let expiration: StorageExpiration
    private(set) var estimatedExpiration: Date
    
    var isExpired: Bool {
      Date().timeIntervalSince(estimatedExpiration) <= 0
    }
    
    init(
      _ value: Value,
      expiration: StorageExpiration
    ) {
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

extension Cache.RequestState: MemorySizeProvider {
  var estimatedMemory: Measurement<UnitInformationStorage> {
    get throws {
      switch self {
      case .response(let response):
        return try response.estimatedMemory
        
        //TODO: 배열 자체도 크기를 갖기 때문에 추후에 수정하면 좋을 거 같습니다.
      case .loading:
        return .init(value: .zero, unit: .bytes)
      }
    }
  }
}

import UIKit

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
