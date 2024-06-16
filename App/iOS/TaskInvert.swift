import Foundation

protocol Requestable<Response>: Identifiable, Sendable {
  associatedtype Response
  func execute() async -> Response
}

actor Cache<Request, Response>
where Request: Requestable<Response>, Response: Sendable
{
  enum RequestState {
    case response(Response)
    case loading([CheckedContinuation<Response, Never>])
  }
  private var cache: [AnyHashable: RequestState] = [:]
  private let streamContinuation: AsyncStream<(Request, CheckedContinuation<Response, Never>)>.Continuation
  private let stream: AsyncStream<(Request, CheckedContinuation<Response, Never>)>

  init() {
    var continuation: AsyncStream<(Request, CheckedContinuation<Response, Never>)>.Continuation!
    self.stream = .init { conti in
      continuation = conti
    }
    self.streamContinuation = continuation
  }

  func run() async {
    await withDiscardingTaskGroup { group in
      for await (request, continuation) in self.stream {
        self.cache[request.id] = .loading([continuation])
        group.addTask {
          let response = await request.execute()
          await self.receivedResponse(for: request.id, response: response)
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

  func executeRequest(_ request: Request) async -> Response {
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
        removeContinuation(for: request.id)
//          await self.removeContinuation(for: request.id)
        // We need to give each continuation an ID by having a counter in the actor
      }
    case .none:
      return await withCheckedContinuation { continuation in
        streamContinuation.yield((request, continuation))
      }
    }
  }

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
