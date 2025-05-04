import 'dart:async';

import 'cache_item.dart';
import 'cache_store.dart';

final class InMemoryCacheStore implements CacheStore {
  InMemoryCacheStore();

  Map<String, String>? _store;

  @override
  Future<int> get cacheVersion async {
    if (_store == null)
      throw StateError(
          'Store not initialised, did you fail to initialise the store?');

    return int.parse(_store!['version'] ?? '-1');
  }

  @override
  Future<void> updateCacheVersion(int version) async {
    if (_store == null)
      throw StateError(
          'Store not initialised, did you fail to initialise the store?');

    _store!['version'] = version.toString();
  }

  @override
  bool containsKey(String key) {
    if (_store == null)
      throw StateError(
          'Store not initialised, did you fail to initialise the store?');

    return _store!.containsKey(key);
  }

  @override
  Future<CacheItem?> getCacheItem(String key) async {
    if (_store == null)
      throw StateError(
          'Store not initialised, did you fail to initialise the store?');

    final item = _store![key];
    if (item == null) return null;

    return CacheItem.fromCacheEntryString(item, key: key);
  }

  @override
  Future<void> initialiseStore() async {
    _store ??= {};
  }

  @override
  Future<void> invalidateCache() async {
    if (_store == null)
      throw StateError(
          'Store not initialised, did you fail to initialise the store?');

    return _store!.clear();
  }

  @override
  Future<void> invalidateCacheItem(String key) async {
    final item = await getCacheItem(key);
    if (item == null) return;

    return await saveCacheItem(
        item.copyWith(persistenceDuration: const Duration(minutes: -5)));
  }

  @override
  Future<void> saveCacheItem(CacheItem item) async {
    _store![item.key] = item.toCacheEntryString();
  }

  @override
  FutureOr<void> close() {
    _store = null;
  }
}
