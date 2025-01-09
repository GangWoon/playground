import Foundation

/// Swift Concurrency Extra 코드
@dynamicMemberLookup
final class LockIsolated<Value>: @unchecked Sendable {
  private var _value: Value
  private let lock = NSRecursiveLock()
  
  init(_ value: Value) {
    self._value = value
  }
  
  public subscript<Subject: Sendable>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
    self.lock.sync {
      self._value[keyPath: keyPath]
    }
  }
  
  
  /// transaction  개념을 배운 부분. 값을 원자적으로 관리하는 방법 중 하나인 구조적 프로그래밍을 사용했습니다.
  /// TaskLocal, Mutext도 비슷한 방식을 채택했습니다.
  public func withValue<T: Sendable>(
    _ operation: @Sendable (inout Value) throws -> T
  ) rethrows -> T {
    try self.lock.sync {
      var value = self._value
      defer { self._value = value }
      return try operation(&value)
    }
  }
  
  public func setValue(_ newValue: @autoclosure @Sendable () throws -> Value) rethrows {
    try self.lock.sync {
      self._value = try newValue()
    }
  }
}

extension LockIsolated where Value: Sendable {
  var value: Value {
    lock.sync {
      self._value
    }
  }
}

extension NSRecursiveLock {
  @inlinable @discardableResult
  public func sync<R>(work: () throws -> R) rethrows -> R {
    self.lock()
    defer { self.unlock() }
    return try work()
  }
}
