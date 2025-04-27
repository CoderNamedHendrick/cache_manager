import 'package:cache_manager/cache_manager.dart';
import 'package:test/test.dart';

void main() {
  group('Multi store cache test suite', () {
    late CacheManager manager;

    setUp(() {
      CacheManager.init(
        stores: [InMemoryCacheStore(), TestInMemoryCacheStore()],
      );
      manager = CacheManager.instance;
    });

    test('verify ephemeral cache item is saved to a single store', () async {
      final item = CacheItem.ephemeral(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
      );

      await manager.set<InMemoryCacheStore>(item);

      expect((await manager.get<InMemoryCacheStore>('test-key-1'))?.isExpired,
          true);

      expect((await manager.get<TestInMemoryCacheStore>('test-key-1')) == null,
          true);
    });

    test('verify ephemeral cache item is saved to a single store', () async {
      final item = CacheItem.ephemeral(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
      );

      await manager.set<TestInMemoryCacheStore>(item);

      expect(
          (await manager.get<TestInMemoryCacheStore>('test-key-1'))?.isExpired,
          true);

      expect(
          (await manager.get<InMemoryCacheStore>('test-key-1')) == null, true);
    });

    // verify set-all updates all stores

    // verify contains method works correctly across stores

    // verify anyContains method works correctly across stores

    // verify invalidate cache item works correctly for single store

    // verify invalidate cache item works correctly for all stores

    // verify cache item expired works for single store

    // verify any cache item expired method

    // verify invalidate cache method works correctly for single store

    // verify invalidate cache method works correctly for all stores
  });
}

final class TestInMemoryCacheStore implements CacheStore {
  TestInMemoryCacheStore();

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
