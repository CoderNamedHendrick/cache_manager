import 'dart:async';

import 'package:cache_manager_plus/cache_manager_plus.dart';
import 'package:test/test.dart';

void main() {
  group('Multi store cache test suite', () {
    late CacheManager manager;

    setUp(() async {
      await CacheManager.init(
        stores: [InMemoryCacheStore(), TestInMemoryCacheStore()],
        forceInit: true,
      );
      manager = CacheManager.instance;
    });

    tearDown(() async {
      await CacheManager.close();
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

    test('verify where returns the correct cache stores', () async {
      final item1 = CacheItem.ephemeral(
        key: 'test-key-1',
        data: 'John',
      );
      final item2 = CacheItem.ephemeral(
        key: 'test-key-1',
        data: 'Doe',
      );

      await manager.set<TestInMemoryCacheStore>(item1);
      await manager.set<InMemoryCacheStore>(item2);

      var stores =
          await manager.where('test-key-1', (item) => item.data == 'Doe');
      expect(stores.length, 1);
      expect(stores.first, isA<InMemoryCacheStore>());

      stores = await manager.where('test-key-1', (item) => item.data == 'John');
      expect(stores.length, 1);
      expect(stores.first, isA<TestInMemoryCacheStore>());
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
    test('invalidate cache item for single store', () async {
      var item = CacheItem.persistent(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
        duration: Duration(seconds: 40),
      );

      await manager.set(item, all: true);

      expect(manager.allContains('test-key-1')?.length, 2);

      expect(
          (await manager.get<InMemoryCacheStore>('test-key-1'))?.isValid, true);
      expect((await manager.get<TestInMemoryCacheStore>('test-key-1'))?.isValid,
          true);

      await manager.invalidateCacheItem<InMemoryCacheStore>('test-key-1');

      expect((await manager.get<InMemoryCacheStore>('test-key-1'))?.isValid,
          false);
      expect((await manager.get<TestInMemoryCacheStore>('test-key-1'))?.isValid,
          true);
    });

    // verify invalidate cache item works correctly for all stores
    test('invalidate cache item for all stores', () async {
      var item = CacheItem.persistent(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
        duration: Duration(seconds: 40),
      );

      await manager.set(item, all: true);

      expect(manager.allContains('test-key-1')?.length, 2);

      expect(
          (await manager.get<InMemoryCacheStore>('test-key-1'))?.isValid, true);
      expect((await manager.get<TestInMemoryCacheStore>('test-key-1'))?.isValid,
          true);

      await manager.invalidateCacheItem('test-key-1', all: true);

      expect((await manager.get<InMemoryCacheStore>('test-key-1'))?.isValid,
          false);
      expect((await manager.get<TestInMemoryCacheStore>('test-key-1'))?.isValid,
          false);
    });

    // verify cache item expired works for single store
    test('cache item expires works', () async {
      var item = CacheItem.persistent(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
        duration: Duration(seconds: 40),
      );

      await manager.set(item, all: true);

      expect(
          (await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-1')),
          false);
      expect(
          (await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-1')),
          false);

      await manager.invalidateCacheItem<InMemoryCacheStore>('test-key-1');

      expect(
          (await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-1')),
          true);
      expect(
          (await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-1')),
          false);
    });

    // verify any cache item expired method
    test('verify any cache item expires returns correctly', () async {
      var item = CacheItem.persistent(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
        duration: Duration(seconds: 40),
      );

      await manager.set(item, all: true);

      expect(
          (await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-1')),
          false);
      expect(
          (await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-1')),
          false);

      await manager.invalidateCacheItem<InMemoryCacheStore>('test-key-1');

      expect((await manager.anyCacheItemExpired('test-key-1')),
          isA<InMemoryCacheStore>());
    });

    // verify invalidate cache method works correctly for single store
    test('invalidate cache works correctly for single stores', () async {
      final storeActions = <Future>[];
      var item = CacheItem.persistent(
        key: 'test-key-2',
        data: {'message': 'Hello world'},
        duration: Duration(seconds: 40),
      );

      storeActions.add(manager.set(item, all: true));

      item = CacheItem.persistent(
        key: 'test-key-3',
        data: {'data': 'look at me'},
        duration: Duration(seconds: 40),
      );

      storeActions.add(manager.set(item, all: true));

      item = CacheItem.persistent(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
        duration: Duration(seconds: 40),
      );

      storeActions.add(manager.set(item, all: true));

      await storeActions.wait;

      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-1'),
          false);
      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-2'),
          false);
      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-3'),
          false);

      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-1'),
          false);
      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-2'),
          false);
      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-3'),
          false);

      await manager.invalidateCache<InMemoryCacheStore>();

      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-1'),
          null);
      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-2'),
          null);
      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-3'),
          null);

      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-1'),
          false);
      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-2'),
          false);
      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-3'),
          false);
    });

    // verify invalidate cache method works correctly for all stores
    test('invalidate cache works correctly for all stores', () async {
      final storeActions = <Future>[];
      var item = CacheItem.persistent(
        key: 'test-key-2',
        data: {'message': 'Hello world'},
        duration: Duration(seconds: 40),
      );

      storeActions.add(manager.set(item, all: true));

      item = CacheItem.persistent(
        key: 'test-key-3',
        data: {'data': 'look at me'},
        duration: Duration(seconds: 40),
      );

      storeActions.add(manager.set(item, all: true));

      item = CacheItem.persistent(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
        duration: Duration(seconds: 40),
      );

      storeActions.add(manager.set(item, all: true));

      await storeActions.wait;

      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-1'),
          false);
      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-2'),
          false);
      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-3'),
          false);

      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-1'),
          false);
      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-2'),
          false);
      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-3'),
          false);

      await manager.invalidateCache(all: true);

      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-1'),
          null);
      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-2'),
          null);
      expect(await manager.isCacheItemExpired<InMemoryCacheStore>('test-key-3'),
          null);

      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-1'),
          null);
      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-2'),
          null);
      expect(
          await manager
              .isCacheItemExpired<TestInMemoryCacheStore>('test-key-3'),
          null);
    });
  });
}

final class TestInMemoryCacheStore implements CacheStore {
  TestInMemoryCacheStore();

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
    _store = {};
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
