import 'dart:async';
import 'dart:developer';

import 'cache_item.dart';
import 'cache_store.dart';

final class CacheManager {
  late final Map<String, CacheStore> _stores;

  CacheManager._();

  static CacheManager? _instance;

  static CacheManager get instance {
    if (_instance == null) {
      throw ArgumentError('Cache not initialized');
    }
    return _instance!;
  }

  static Future<void> init({
    CacheStore? store,
    List<CacheStore> stores = const [],
  }) async {
    assert(store != null || stores.isNotEmpty,
        'At least one store must be provided');

    if (store == null && stores.isEmpty) {
      throw ArgumentError('At least one store must be provided');
    }

    _instance = CacheManager._();
    _instance!._stores = {
      if (store != null) store.runtimeType.toString(): store,
      for (final store in stores) store.runtimeType.toString(): store,
    };

    await Future.wait(
      instance._stores.values.map((store) => store.initialiseStore()),
    );
  }

  static void close() {
    _instance = null;
  }

  Future<int> cacheVersion<S extends CacheStore>() async {
    return await _effectiveStore(S.toString()).cacheVersion;
  }

  Future<void> updateCacheVersion<S extends CacheStore>(int version) async {
    return await _effectiveStore(S.toString()).updateCacheVersion(version);
  }

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

  FutureOr<CacheItem?> get<S extends CacheStore>(String key) async {
    final store = _effectiveStore(S.toString());
    final item = await store.getCacheItem(key);
    if (item != null) {
      log('returning cache item sync for $key in ${store.runtimeType}');
    }
    return item;
  }

  bool contains<S extends CacheStore>(String key) {
    return _effectiveStore(S.toString()).containsKey(key);
  }

  String? anyContains(String key) {
    for (final store in _stores.values) {
      if (store.containsKey(key)) return store.runtimeType.toString();
    }

    return null;
  }

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

  FutureOr<bool> cacheItemExpired<S extends CacheStore>(String key) async {
    final item = await _effectiveStore(S.toString()).getCacheItem(key);
    return item?.isExpired ?? true;
  }

  Future<String?> anyCacheItemExpired(String key) async {
    for (final store in _stores.values) {
      if (await _effectiveStore(store.runtimeType.toString()).getCacheItem(key)
          case final CacheItem item when item.isExpired) {
        return store.runtimeType.toString();
      }
    }

    return null;
  }

  Future<void> invalidateCache<S extends CacheStore>([bool all = false]) async {
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
