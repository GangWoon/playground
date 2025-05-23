import Foundation

extension Cache {
  final class Storage: IterableCache<String, CacheItem<RequestState>>, NSCacheDelegate {
    override init(totalCostLimit: Int) {
      super.init(totalCostLimit: totalCostLimit)
      self.cache.delegate = self
    }
    
    func setRequestState(
      _ value: RequestState,
      forKey key: String,
      cost: Int = 0
    ) {
      setObject(
        CacheItem(
          key: key,
          value: value,
          expiration: ExpirationLocals.value
        ),
        forKey: key,
        cost: cost
      )
    }
    
    func extendCacheItem(forKey key: String) {
      if let cacheItem = object(forKey: key), !cacheItem.isExpired {
        cacheItem.extendExpiration()
      }
    }
    
    // MARK: - NSCacheDelegate
    func cache(
      _ cache: NSCache<AnyObject, AnyObject>,
      willEvictObject object: Any
    ) {
      guard let state = object as? CacheItem<RequestState>
      else { return }
      if let task = state.task {
        task.cancel()
      } else {
        keys.remove(state.key)
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
    Date().timeIntervalSince(estimatedExpiration) >= 0
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
    get { value[keyPath: keyPath] }
  }
}
