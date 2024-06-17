import Foundation

public protocol Requestable<Response>: Identifiable, Sendable where Response: Sendable {
  associatedtype Response
  func execute() async throws -> Response
}

public actor Cache<Request, Response> where Request: Requestable<Response> {
  enum RequestState {
    case response(Response)
    case loading([CheckedContinuation<Response, Never>])
  }
  private var cache: [AnyHashable: RequestState] = [:]
  private let streamContinuation: AsyncStream<(Request, CheckedContinuation<Response, Never>)>.Continuation
  private let stream: AsyncStream<(Request, CheckedContinuation<Response, Never>)>

  public init() {
    var continuation: AsyncStream<(Request, CheckedContinuation<Response, Never>)>.Continuation!
    self.stream = .init { conti in
      continuation = conti
    }
    self.streamContinuation = continuation
  }

  public func run() async {
    await withDiscardingTaskGroup { group in
      for await (request, continuation) in self.stream {
        self.cache[request.id] = .loading([continuation])
        group.addTask {
          do {
            let response = try await request.execute()
            await self.receivedResponse(for: request.id, response: response)
          } catch { }
        }
      }
    }
  }

  private func receivedResponse(for id: AnyHashable, response: Response) {
    if case .loading(let continuations) = self.cache[id] {
      self.cache[id] = .response(response)
      for continuation in continuations {
        continuation.resume(returning: response)
      }
    }
  }

  public func executeRequest(_ request: Request) async -> Response {
    switch self.cache[request.id] {
    case .response(let response):
      return response
    case .loading(var continuations):
      return await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
          continuations.append(continuation)
          self.cache[request.id] = .loading(continuations)
        }
      } onCancel: {
        /// Yes that's a correct error. The one way to work around this with Cache being an actor is to again spawn an unstructured task.
        /// This shows that we probably hit the limit of what we can do with an actor here and it might be time to switch to a class and use Mutex instead to protect our state.
        /// This way we don't need an async call to remove the continuation from onCancel.
        ///
        /// class로 변경해서 mutax가 아니더라도 nslock을 사용하면 될 거 같았지만, 전혀 원치 않는 결과를 초래함.
        /// Task를 cancel시켜도, continuations 배열에서 제거되지 않음.
        /// control invert 컨셉에서는 아래와 같이 Task를 생성하면 안되지만, 원하는 결과 값이랑 가장 유사하게 동작하는 코드.
        //MARK: - TODO: control invert 컨셉에 맞게 수정하기
        Task {
          // We need to give each continuation an ID by having a counter in the actor
          await removeContinuation(for: request.id)
        }
      }
    case .none:
      return await withCheckedContinuation { continuation in
        streamContinuation.yield((request, continuation))
      }
    }
  }

  /// 마지막꺼 지우는게 아닌, 배열에서 정확하게 누구인지 찾아서 지워야함.
  private func removeContinuation(for id: AnyHashable) {
    if case .loading(var continuations) = self.cache[id], !continuations.isEmpty {
      continuations.removeLast()
      if continuations.isEmpty {
        self.cache.removeValue(forKey: id)
      } else {
        self.cache[id] = .loading(continuations)
      }
    }
  }
}

struct TempRequest: Requestable {
  let id: Int
  
  func execute() async throws -> Int {
    try await Task.sleep(for: .seconds(3))
    
    return 3
  }
}

extension Cache<TempRequest, Int> {
  @MainActor
  static var intCache = Cache<TempRequest, Int>()
}
