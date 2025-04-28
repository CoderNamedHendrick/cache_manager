import 'package:cache_manager/cache_manager.dart';
import 'package:test/test.dart';

void main() {
  group('Cache test suite', () {
    late CacheManager manager;
    setUp(() {
      CacheManager.init(store: InMemoryCacheStore(), forceInit: true);
      manager = CacheManager.instance;
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

    test('persistent cache items last as long as their specified duration', () async {
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
  });
}
