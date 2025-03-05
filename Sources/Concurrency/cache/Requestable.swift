public protocol Requestable<ID>: Sendable {
  associatedtype ID: CustomStringConvertible, Sendable
  associatedtype Response: MemorySizeProvider
  nonisolated func execute(id: ID) async throws -> Response
}
