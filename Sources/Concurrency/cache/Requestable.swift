public protocol Requestable<ID>: Sendable {
  associatedtype ID: CustomStringConvertible
  associatedtype Response: MemorySizeProvider
  func execute(id: ID) async throws -> Response
}
