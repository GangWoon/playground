import Foundation

extension Cache {
  final class Storage: IterableCache<String, CacheItem<Request.Response>>, NSCacheDelegate {
    private var removedContinuations: [String: RequestState.LoadingState] = [:]
    
    override init(totalCostLimit: Int) {
      super.init(totalCostLimit: totalCostLimit)
      self.cache.delegate = self
    }
    
    override func removeObject(forKey key: String) {
      super.removeObject(forKey: key)
      removedContinuations[key] = nil
    }
    
    override func removeAllObjects() {
      for key in keys {
        removedContinuations[key]?.task.cancel()
      }
      super.removeAllObjects()
    }
    
    override func contains(forKey key: String) -> Bool {
      return super.contains(forKey: key) || removedContinuations.keys.contains(key)
    }
    
    func requestState(forKey key: String) -> RequestState? {
      if let loadingState = removedContinuations[key] {
        return .loading(loadingState)
      } else if let response = object(forKey: key) {
        return .response(response.boxedValue)
      }
      return nil
    }
    
    func setRequestState(
      _ value: RequestState,
      forKey key: String,
      cost: Int = 0
    ) {
      switch value {
      case .response(let response):
        removedContinuations[key] = nil
        setObject(
          .init(
            key: key,
            value: response,
            expiration: ExpirationLocals.value
          ),
          forKey: key,
          cost: cost
        )
      case .loading(let loadingState):
        removedContinuations[key] = loadingState
      }
    }
    
    func loadingState(forKey key: String) -> RequestState.LoadingState? {
      lock.withLock { removedContinuations[key] }
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
      guard let item = object as? CacheItem<Request.Response> else {
        return
      }
      keys.remove(item.key)
    }
  }
}

enum ExpirationLocals {
  @TaskLocal static var value: StorageExpiration = .expired
}

@dynamicMemberLookup
final class CacheItem<Value> {
  let key: String
  private var value: Value
  let expiration: StorageExpiration
  
  var boxedValue: Value {
    _read { yield value }
    _modify { yield &value }
  }
  
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
  
  public subscript<Member>(dynamicMember keyPath: WritableKeyPath<Value, Member>) -> Member {
    get { boxedValue[keyPath: keyPath] }
    set { boxedValue[keyPath: keyPath] = newValue }
  }
}
