public protocol Requestable<ID>: Sendable {
  associatedtype ID: Hashable, Sendable, CustomStringConvertible
  associatedtype Response: MemorySizeProvider
  func execute(id: ID) async throws -> Response
}
