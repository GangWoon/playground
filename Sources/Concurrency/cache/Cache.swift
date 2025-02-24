import UIKit.UIApplication
import Foundation
import Combine

public final actor Cache<Request: Requestable>: Sendable {
  let request: Request
  let configuration: Configuration
  let storage: Storage
  private var memoryWarningTask: Task<Void, Never>?
  private var cleanupTask: Task<Void, Never>?
  
  public init(
    request: Request,
    configuration: Configuration = Configuration(),
    dependency: Dependecny = .liveValue
  ) {
    self.request = request
    self.configuration = configuration
    self.storage = Storage(totalCostLimit: configuration.limit.cost)
    
    Task {
      await prepare(dependency: dependency)
    }
  }
  
  private func prepare(dependency: Dependecny) {
    memoryWarningTask = Task { [weak self] in
      let stream = dependency
        .memoryWarningStream()
        .values
      for await _ in stream {
        guard let self, !Task.isCancelled else {
          return
        }
        await self.removeAllObjects()
      }
    }
    
    let cleanupInterval = configuration.cleanupInterval
    cleanupTask = Task { [weak self] in
      let stream = dependency
        .cleanupTimerStream(cleanupInterval)
      for await _ in stream {
        guard let self, !Task.isCancelled else {
          return
        }
        await self.removeExpiredCacheItem()
      }
    }
  }
  
  private func removeAllObjects() {
    storage.removeAllObjects()
  }
  
  private func removeExpiredCacheItem() {
    for (key, item) in storage where item.isExpired {
      storage.removeObject(forKey: key)
    }
  }
  
  deinit {
    memoryWarningTask?.cancel()
    cleanupTask?.cancel()
  }
  
  public func execute(
    id: Request.ID,
    expiration: StorageExpiration? = nil
  ) async throws -> Request.Response {
    let task = storage.loadingState(forKey: id.description)?.task
    guard !Task.isCancelled else {
      task?.cancel()
      throw CancellationError()
    }
    
    return try await withTaskCancellationHandler {
      try await withUnsafeThrowingContinuation { continuation in
        let key = id.description
        switch storage.requestState(forKey: key) {
        case .response(let response):
          continuation.resume(returning: response)
          storage.extendCacheItem(forKey: key)
          
        case .loading(let loadingState):
          loadingState.continuations.append(continuation)
          
        case nil:
          ExpirationLocals.$value.withValue(expiration ?? configuration.expiration) {
            storage.setRequestState(
              .loading(.init(task: initialTask(id), continuations: [continuation])),
              forKey: key
            )
          }
        }
      }
    } onCancel: {
      task?.cancel()
    }
  }
  
  private func initialTask(_ id: Request.ID) -> Task<Void, Never> {
    Task {
      do {
        let response = try await request.execute(id: id)
        let key = id.description
        let continuations = storage
          .loadingState(forKey: key)?
          .continuations ?? []
        storage.setRequestState(
          .response(response),
          forKey: key,
          cost: try response.estimatedMemory.cost
        )
        
        for continuation in continuations {
          continuation.resume(returning: response)
          await Task.yield()
        }
      } catch {
        _cancel(for: id, error: error)
      }
    }
  }
  
  public nonisolated func cancel(id: sending Request.ID) {
    Task {
      nonisolated(unsafe) let id = id
      await _cancel(for: id)
    }
  }
  
  private func _cancel(
    for id: sending Request.ID,
    error: any Error = CancellationError()
  ) {
    let continuations = storage
      .loadingState(forKey: id.description)?
      .continuations ?? []
    storage.removeObject(forKey: id.description)
    guard !continuations.isEmpty else {
      return
    }
    
    Task {
      for continuation in continuations {
        continuation.resume(throwing: error)
        await Task.yield()
      }
    }
  }
  
  public func isCached(id: Request.ID) -> Bool {
    storage.contains(forKey: id.description)
  }
}

extension Cache {
  public struct Configuration: Sendable {
    let limit: Measurement<UnitInformationStorage>
    let expiration: StorageExpiration
    let cleanupInterval: TimeInterval
    
    public init(
      limit: Measurement<UnitInformationStorage> = .memoryLimit,
      expiration: StorageExpiration = .seconds(300),
      cleanupInterval: TimeInterval = 120
    ) {
      self.limit = limit
      self.expiration = expiration
      self.cleanupInterval = cleanupInterval
    }
  }
  
  typealias Continuation = UnsafeContinuation<Request.Response, any Error>
  enum RequestState {
    case response(Request.Response)
    
    class LoadingState {
      let task: Task<Void, Never>
      var continuations: [Continuation]
      init(task: Task<Void, Never>, continuations: [Continuation]) {
        self.task = task
        self.continuations = continuations
      }
    }
    var loadingState: LoadingState? {
      get {
        guard case .loading(let state) = self else {
          return nil
        }
        return state
      }
      set {
        guard let newValue else {
          return
        }
        self = .loading(newValue)
      }
    }
    case loading(LoadingState)
  }
  
  public struct Dependecny: Sendable {
    public var memoryWarningStream: @Sendable () -> AnyPublisher<Void, Never>
    public var cleanupTimerStream: @Sendable (Double) -> AsyncStream<Void>
    
    public init(
      memoryWarningStream: @Sendable @escaping () -> AnyPublisher<Void, Never>,
      cleanupTimerStream: @Sendable @escaping (Double) -> AsyncStream<Void>
    ) {
      self.memoryWarningStream = memoryWarningStream
      self.cleanupTimerStream = cleanupTimerStream
    }
  }
}

extension Cache.Dependecny {
  public static var liveValue: Self {
    .init(
      memoryWarningStream: {
        NotificationCenter.default
          .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
          .map { _ in () }
          .eraseToAnyPublisher()
      },
      cleanupTimerStream: { value in
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let task = Task {
          while true {
            try await Task.sleep(for: .seconds(value))
            continuation.yield()
          }
        }
        continuation.onTermination = { _ in
          task.cancel()
        }
        
        return stream
      }
    )
  }
}

extension Measurement where UnitType == UnitInformationStorage {
  var cost: Int {
    Int(converted(to: .bytes).value)
  }
}
