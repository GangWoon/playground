import Foundation

extension Cache {
  class Storage: IterableCache<String, CacheItem<RequestState>>, NSCacheDelegate {
    var removedContinuations: [String: [Continuation]] = [:]
    
    override init(totalCostLimit: Int) {
      super.init(totalCostLimit: totalCostLimit)
      self.cache.delegate = self
    }
    
    override func removeObject(forKey key: String) {
      super.removeObject(forKey: key)
      removedContinuations[key] = nil
    }
    
    func setRequestState(
      _ value: RequestState,
      forKey key: String,
      cost: Int = 0
    ) {
      let cacheItem = CacheItem<RequestState>(
        key: key,
        value: value,
        expiration: ExpirationLocals.value
      )
      super.setObject(cacheItem, forKey: key, cost: cost)
    }
    
    func continuations(forKey key: String) -> [Continuation] {
      lock.lock()
      defer { lock.unlock() }
      return object(forKey: key)?.value.loadingState?.continuations
      ?? removedContinuations[key]
      ?? []
    }
    
    // MARK: - NSCacheDelegate
    /// loading 상태에서 캐시 정책에 의해서 제거될 경우, 값을 저장해서 전파하기 위해서.
    func cache(
      _ cache: NSCache<AnyObject, AnyObject>,
      willEvictObject obj: Any
    ) {
      guard let box = obj as? CacheItem<RequestState> else { return }
      let key = box.key
      switch box.value {
      case .response:
        removedContinuations[key] = nil
        keys.remove(key)
      case .loading(let state):
        removedContinuations[box.key] = state.continuations
      }
    }
  }
}

enum ExpirationLocals {
  @TaskLocal static var value: StorageExpiration = .expired
}

@dynamicMemberLookup
final class CacheItem<Value> {
  let key: String
  var value: Value
  let expiration: StorageExpiration
  
  var isExpired: Bool {
    Date().timeIntervalSince(estimatedExpiration) <= 0
  }
  private(set) var estimatedExpiration: Date
  
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
      estimatedExpiration = expiration.estimatedExpirationSinceNow
    case .expirationTime(let expiration):
      estimatedExpiration = expiration.estimatedExpirationSinceNow
    }
  }
  
  public subscript<Member>(dynamicMember keyPath: KeyPath<Value, Member>) -> Member {
    value[keyPath: keyPath]
  }
}
