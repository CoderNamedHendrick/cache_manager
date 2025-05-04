import 'dart:async';
import 'dart:developer';

import 'cache_item.dart';
import 'cache_store.dart';

/// [CacheManager] for orchestrating access to [CacheStore]/(s),
/// call [init] to initialise the manager with one or multiple [CacheStore]
final class CacheManager {
  late final Map<String, CacheStore> _stores;

  CacheManager._();

  static CacheManager? _instance;

  /// [CacheManager] singleton instance
  static CacheManager get instance {
    if (_instance == null) {
      throw ArgumentError('CacheManager not initialized');
    }
    return _instance!;
  }

  /// Initialises [CacheManager] with respective [CacheStore]-(s)
  /// pass [CacheStore] to [store] when working with only a single [CacheStore]
  /// and to [stores] when working with multiple stores. Use [forceInit] to ensure
  /// the manager is reinitialised
  /// example
  /// ```dart
  /// void main() {
  ///   CacheManager.init(store: InMemoryCacheStore()); // single store mode
  ///   CacheManager.init(
  ///     stores: \[ InMemoryCacheStore(), HiveCacheStore(), OtherCacheStore() \],
  ///   );
  /// }
  ///
  /// ```
  static Future<void> init({
    CacheStore? store,
    List<CacheStore> stores = const [],
    bool forceInit = false,
  }) async {
    if (store == null && stores.isEmpty) {
      throw ArgumentError('At least one store must be provided');
    }

    if (forceInit) {
      await close(); // safe closes all stores
      _instance = CacheManager._();
    } else {
      if (_instance != null) {
        throw StateError(
            'Cache manager has already been initialised, force initialisation instead?');
      }
      _instance ??= CacheManager._();
    }

    _instance!._stores = {};
    if (store case final CacheStore s) {
      _instance!._stores.putIfAbsent(s.runtimeType.toString(), () => s);
    }
    for (final store in stores) {
      _instance!._stores.putIfAbsent(store.runtimeType.toString(), () => store);
    }

    await Future.wait(
      instance._stores.values.map((store) => store.initialiseStore()),
    );
  }

  /// closes all stores
  static Future<void> close() async {
    if (_instance != null) {
      await _instance!._stores.values
          .map((store) async => await store.close())
          .wait;
      _instance = null;
    }
  }

  /// retrieves all [CacheStore] that matches the [predicate]
  Future<Iterable<CacheStore>> where(
      String key, bool Function(CacheItem i) predicate) async {
    List<CacheStore> s = [];
    for (final store in _stores.values) {
      if (await store.getCacheItem(key) case final CacheItem it) {
        if (predicate(it)) s.add(store);
      }
    }

    return s;
  }

  /// retrieves the [CacheStore] version for the [CacheStore] specified by
  /// the method's generic type[S] or the first [CacheStore] in the manager stores.
  Future<int> cacheVersion<S extends CacheStore>() async {
    return await _effectiveStore(S.toString()).cacheVersion;
  }

  /// updates the [CacheStore] version for the [CacheStore] specified by
  /// the method's generic type [S] or the first [CacheStore] in the manager.
  /// All [CacheStore] in the manager can be updated by setting [all] to true
  Future<void> updateCacheVersion<S extends CacheStore>(int version,
      {bool all = false}) async {
    return await _effectiveStore(S.toString()).updateCacheVersion(version);
  }

  /// sets the [CacheItem] in the [CacheStore] specified by the method's
  /// generic type [S] or the first [CacheStore] in the manager.
  /// The [CacheItem] can be set in all [CacheStore] in the manager by setting
  /// [all] to true
  Future<void> set<S extends CacheStore>(CacheItem item,
      {bool all = false}) async {
    if (all) {
      log('setting cache data for ${item.key} in all stores');
      await _stores.values.map((store) => store.saveCacheItem(item)).wait;
      return;
    }

    final store = _effectiveStore(S.toString());
    log('setting cache data for ${item.key} in ${store.runtimeType}');
    return await store.saveCacheItem(item);
  }

  /// gets the [CacheItem] in the [CacheStore] specified by the method's
  /// generic type [S] or the first [CacheStore] in the manager.
  /// The method returns null if the [CacheItem] isn't found
  FutureOr<CacheItem?> get<S extends CacheStore>(String key) async {
    final store = _effectiveStore(S.toString());
    final item = await store.getCacheItem(key);
    if (item != null) {
      log('returning cache item sync for $key in ${store.runtimeType}');
    }
    return item;
  }

  /// checks if a [CacheItem] key exists in the [CacheStore] specified
  /// by the method's generic type [S] or the first [CacheStore] in the manager.
  bool contains<S extends CacheStore>(String key) {
    return _effectiveStore(S.toString()).containsKey(key);
  }

  /// returns the first [CacheStore] where the key is found, it returns
  /// null if it fails to find any store with the key
  CacheStore? anyContains(String key) {
    for (final store in _stores.values) {
      if (store.containsKey(key)) return store;
    }

    return null;
  }

  /// returns all [CacheStore] where key is found,
  /// returns null if no store with key is found
  Iterable<CacheStore>? allContains(String key) {
    final foundStores = <CacheStore>[];

    for (final store in _stores.values) {
      if (store.containsKey(key)) foundStores.add(store);
    }

    return foundStores.isNotEmpty ? foundStores : null;
  }

  /// invalidates [CacheItem] with the [key] in the [CacheStore] specified
  /// by the method's generic type [S] or the first [CacheStore] in the manager.
  /// Invalidate [CacheItem] in all [CacheStore] by setting [all] to true
  Future<void> invalidateCacheItem<S extends CacheStore>(String key,
      {bool all = false}) async {
    Future<void> invalidateItemInCache(CacheStore store) async {
      if (!store.containsKey(key)) {
        return;
      }
      log('invalidating cache item for $key in ${store.runtimeType}');
      return await store.invalidateCacheItem(key);
    }

    if (all) {
      await _stores.values.map((store) => invalidateItemInCache(store)).wait;
      return;
    }

    return await invalidateItemInCache(_effectiveStore(S.toString()));
  }

  /// helper method to check if a [CacheItem] is expired/valid. It returns a
  /// nullable boolean with null being returned when the item doesn't exist
  /// in the [CacheStore] specified by the method's generic type [S]
  /// or the first [CacheStore] in the manager
  FutureOr<bool?> isCacheItemExpired<S extends CacheStore>(String key) async {
    final item = await _effectiveStore(S.toString()).getCacheItem(key);
    return item?.isExpired;
  }

  /// returns the first [CacheStore] where the [key] exists and has expired
  /// in the [CacheManager]
  Future<CacheStore?> anyCacheItemExpired(String key) async {
    for (final store in _stores.values) {
      if (await _effectiveStore(store.runtimeType.toString()).getCacheItem(key)
          case final CacheItem item when item.isExpired) {
        return store;
      }
    }

    return null;
  }

  /// invalidates all [CacheItem] in a [CacheStore],
  /// specified by the method's generic type [S] or the first [CacheStore] in the manager.
  /// when [all] is true, it invalidates all [CacheStore] in the [CacheManager].
  /// How did operation invalidates the store is dependent on the [CacheStore] implementation
  /// with the simplest being clearing the store so no keys exist in the [CacheStore].
  Future<void> invalidateCache<S extends CacheStore>({bool all = false}) async {
    if (all) {
      log('invalidating all caches items');
      await _stores.values.map((store) => store.invalidateCache()).wait;
      return;
    }

    final store = _effectiveStore(S.toString());
    log('invalidating all cache items in ${store.runtimeType.toString()}');
    return await store.invalidateCache();
  }

  CacheStore _effectiveStore(String identifier) {
    assert(_stores.isNotEmpty, 'there must be at least one cache store');
    return _stores[identifier] ?? _stores.values.first;
  }
}
