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

    test('verify set all updates all cache stores', () async {
      final item = CacheItem.ephemeral(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
      );

      await manager.set(item, all: true);

      expect((await manager.get<TestInMemoryCacheStore>('test-key-1')) != null,
          true);
      expect(
          (await manager.get<InMemoryCacheStore>('test-key-1')) != null, true);
    });

    test('verify contains method works correctly across stores', () async {
      var item = CacheItem.ephemeral(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
      );

      await manager.set<InMemoryCacheStore>(item);

      expect(manager.contains<InMemoryCacheStore>('test-key-1'), true);
      expect(manager.contains<TestInMemoryCacheStore>('test-key-1'), false);

      item = CacheItem.persistent(
        key: 'test-key-2',
        data: {'message': 'Hello world'},
        duration: Duration(seconds: 3),
      );

      await manager.set<TestInMemoryCacheStore>(item);

      expect(manager.contains<InMemoryCacheStore>('test-key-2'), false);
      expect(manager.contains<TestInMemoryCacheStore>('test-key-2'), true);
    });

    test('verify any contains updates all stores', () async {
      var item = CacheItem.ephemeral(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
      );

      await manager.set<InMemoryCacheStore>(item);

      expect(manager.anyContains('test-key-1'), isA<InMemoryCacheStore>());

      item = CacheItem.persistent(
        key: 'test-key-2',
        data: {'message': 'Hello world'},
        duration: Duration(seconds: 3),
      );

      await manager.set<TestInMemoryCacheStore>(item);

      expect(manager.anyContains('test-key-2'), isA<TestInMemoryCacheStore>());

      expect(manager.anyContains('test-key-3'), null);
    });

    test('all contains works correctly across stores', () async {
      var item = CacheItem.ephemeral(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
      );

      await manager.set(item, all: true);

      expect(manager.allContains('test-key-1')?.length, 2);

      expect(manager.allContains('test-key-2'), null);
    });

    // verify invalidate cache item works correctly for single store
    test('invalidate cache item for single store', () async {});

    // verify invalidate cache item works correctly for all stores
    test('invalidate cache item for all stores', () async {});

    // verify cache item expired works for single store
    test('cache item expires works', () async {});

    // verify any cache item expired method
    test('verify any cache item expires returns correctly', () async {});

    // verify invalidate cache method works correctly for single store
    test('invalidate cache works correctly for single stores', () async {});

    // verify invalidate cache method works correctly for all stores
    test('invalidate cache works correctly for all stores', () async {});
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
