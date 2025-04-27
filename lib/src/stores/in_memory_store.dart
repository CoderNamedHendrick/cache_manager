import '../cache/cache.dart';

final class InMemoryCacheStore implements CacheStore {
  InMemoryCacheStore();

  late final Map<String, String> _store;

  @override
  Future<int> get cacheVersion async {
    return int.parse(_store['version'] ?? '-1');
  }

  @override
  Future<void> updateCacheVersion(int version) async {
    _store['version'] = version.toString();
  }

  @override
  bool containsKey(String key) {
    return _store.containsKey(key);
  }

  @override
  Future<CacheItem?> getCacheItem(String key) async {
    final item = _store[key];
    if (item == null) return null;

    return CacheItem.fromCacheEntryString(item, key: key);
  }

  @override
  Future<void> initialiseStore() async {
    _store = {};
  }

  @override
  Future<void> invalidateCache() async {
    return _store.clear();
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
    _store[item.key] = item.toCacheEntryString();
  }
}
