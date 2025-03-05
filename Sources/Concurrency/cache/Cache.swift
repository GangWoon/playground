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
    let key = id.description
    let task: Task<Request.Response, any Error> = if storage.object(forKey: key) == nil {
      let task = initialTask(id)
      
      return task
    } else {
      storage.object(forKey: key)!.task!
    }
    guard !Task.isCancelled else {
      task.cancel()
      throw CancellationError()
    }
    
    return try await withTaskCancellationHandler {
      let key = id.description
      switch storage.object(forKey: key)?.boxedValue {
      case .response(let response):
        storage.extendCacheItem(forKey: key)
        return response
        
      case .loading(let loadingState):
        return try await loadingState.value
        
      case nil:
        return try await task.value
      }
    } onCancel: {
      task.cancel()
    }
  }
  
  private func initialTask(_ id: sending Request.ID) -> Task<Request.Response, any Error> {
    Task {
      do {
        let response = try await request.execute(id: id)
        let key = id.description
        storage.setRequestState(
          .response(response),
          forKey: key,
          cost: try response.estimatedMemory.cost
        )
        return response
      } catch {
        _cancel(for: id, error: error)
        throw error
      }
    }
  }
  
  public nonisolated func cancel(id: sending Request.ID) {
    Task {
      await _cancel(for: id)
    }
  }
  
  private func _cancel(
    for id: sending Request.ID,
    error: any Error = CancellationError()
  ) {
    let key = id.description
    storage.object(forKey: key)?.task?.cancel()
    storage.removeObject(forKey: key)
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
    var task: Task<Request.Response, any Error>? {
      guard case .loading(let task) = self else {
        return nil
      }
      return task
    }
    case loading(Task<Request.Response, any Error>)
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
