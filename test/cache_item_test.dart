import 'package:cache_manager_plus/cache_manager_plus.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Cache item test', () {
    test('equality comparison', () {
      final a = CacheItem.ephemeral(key: 'a', data: 'Data a')
          .copyWith(expiry: DateTime(1900));
      final b = CacheItem.ephemeral(key: 'a', data: 'Data a')
          .copyWith(expiry: DateTime(1900));

      expect(a == b, true);
    });

    test('persistence duration update', () {
      var a = CacheItem.ephemeral(key: 'a', data: 'data a');

      expect(a.isExpired, true);

      a = a.copyWith(persistenceDuration: Duration(minutes: 20));
      expect(a.isExpired, false);

      a = a.copyWith(
          expiry: DateTime.now().add(Duration(minutes: 10)),
          persistenceDuration: Duration(minutes: -20));
      expect(a.isExpired, true);
      final expiry = a.expiry;

      a = a.copyWith();

      expect(a.expiry, expiry);
    });
  });
}
