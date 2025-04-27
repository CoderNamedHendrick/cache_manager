// coverage:ignore-file

import 'package:hive/hive.dart';
import '../cache/cache.dart';

final class HiveCacheStore implements CacheStore {
  final String path;
  final HiveStorageBackendPreference backendPreference;
  final String boxName;

  late final Box<String> _store;

  HiveCacheStore({
    required this.path,
    this.backendPreference = HiveStorageBackendPreference.native,
    this.boxName = 'cache-store',
  });

  @override
  Future<int> get cacheVersion async {
    final version = _store.get('version');
    if (version == null) return -1;

    return int.parse(version);
  }

  @override
  Future<void> updateCacheVersion(int version) async {
    return await _store.put('version', version.toString());
  }

  @override
  bool containsKey(String key) {
    return _store.containsKey(key);
  }

  @override
  Future<CacheItem?> getCacheItem(String key) async {
    final item = _store.get(key);
    if (item == null) return null;

    return CacheItem.fromCacheEntryString(item, key: key);
  }

  @override
  Future<void> initialiseStore() async {
    Hive.init(path, backendPreference: backendPreference);
    _store = await Hive.openBox(boxName);
  }

  @override
  Future<void> invalidateCache() async {
    await _store.clear();
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
    return await _store.put(item.key, item.toCacheEntryString());
  }
}
