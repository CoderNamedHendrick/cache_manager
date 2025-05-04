import 'package:cache_manager_plus/cache_manager_plus.dart';
import 'package:test/test.dart';

void main() {
  group('Cache test suite', () {
    late CacheManager manager;
    setUp(() async {
      await CacheManager.init(store: InMemoryCacheStore(), forceInit: true);
      manager = CacheManager.instance;
    });

    tearDown(() async {
      await CacheManager.close();
    });

    test('not passing any store throws error', () async {
      await CacheManager.close();

      expect(
        CacheManager.init(),
        throwsA(
          isArgumentError.having((p0) => p0.message, 'invalid arguments error',
              'At least one store must be provided'),
        ),
      );
    });

    test('re-initialisation without forcing throw error', () async {
      expect(
        CacheManager.init(store: InMemoryCacheStore()),
        throwsA(
          isStateError.having(
            (p0) => p0.message,
            'state error message',
            'Cache manager has already been initialised, force initialisation instead?',
          ),
        ),
      );
    });

    test('update cache version', () async {
      expect(await manager.cacheVersion(), -1);

      manager.updateCacheVersion(1);

      expect(await manager.cacheVersion(), 1);
    });

    test('ephemeral cache items expire immediately', () async {
      final item = CacheItem.ephemeral(
        key: 'test-key-1',
        data: {'name': 'John Doe'},
      );

      manager.set(item);

      final cachedItem = await manager.get<InMemoryCacheStore>('test-key-1');
      expect(cachedItem?.isExpired, true);
      expect(cachedItem?.data, {'name': 'John Doe'});
    });

    test('persistent cache items last as long as their specified duration',
        () async {
      final item = CacheItem.persistent(
        key: 'test-key-2',
        data: {'message': 'Hello world'},
        duration: Duration(seconds: 3),
      );

      manager.set(item);

      final cachedItem = await manager.get('test-key-2');
      expect(cachedItem?.isExpired, false);
      expect(cachedItem?.data, {'message': 'Hello world'});

      await Future.delayed(Duration(seconds: 3));

      expect(cachedItem?.isExpired, true);
      expect(cachedItem?.data, {'message': 'Hello world'});
    });

    test('override expiry on persistent cache item', () async {
      final item = CacheItem.persistent(
        key: 'test-key-3',
        data: {'data': 'look at me'},
        duration: Duration(seconds: 40),
      );

      manager.set(item);

      final cachedItem = await manager.get('test-key-3');
      expect(cachedItem?.isExpired, false);
      expect(cachedItem?.data, {'data': 'look at me'});

      manager.set(item.copyWith(persistenceDuration: Duration.zero));

      final updatedCachedItem = await manager.get('test-key-3');
      expect(updatedCachedItem?.isExpired, true);
      expect(updatedCachedItem?.data, {'data': 'look at me'});
    });

    test('close store and reinitialise', () async {
      final item = CacheItem.persistent(
        key: 'test-key-3',
        data: {'data': 'look at me'},
        duration: Duration(seconds: 40),
      );

      CacheManager.instance.set(item);

      var cachedItem = await CacheManager.instance.get('test-key-3');
      expect(cachedItem?.isExpired, false);

      await CacheManager.close();

      expect(
        () async {
          await CacheManager.instance.set(item);
        }(),
        throwsA(
          isArgumentError.having(
            (p0) => p0.message,
            'state error message',
            'CacheManager not initialized',
          ),
        ),
      );

      CacheManager.init(store: InMemoryCacheStore());

      CacheManager.instance.set(item);

      cachedItem = await CacheManager.instance.get('test-key-3');
      expect(cachedItem?.isExpired, false);
    });
  });
}
