//coverage:ignore-file

import 'dart:async';

import '../../cache_manager_plus.dart';

/// contract defining the shape of a [CacheStore] used to create
/// custom stores that are passed to the [CacheManager] to orchestrate
/// communication with
abstract interface class CacheStore {
  /// returns the current version of the store
  /// in store implementations, -1 is returned when there's no version number
  Future<int> get cacheVersion;

  /// update the [CacheStore] version
  Future<void> updateCacheVersion(int version);

  /// does the work to initialise the store, wholly dependent
  /// on the implementation details
  /// for example in [HiveCacheStore] which uses Hive for storage
  /// ```dart
  /// final class HiveCacheStore implements CacheStore {
  /// final String path;
  ///   final HiveStorageBackendPreference backendPreference;
  ///   final String boxName;
  ///
  ///   late final Box<String> _store;
  ///
  ///   HiveCacheStore({
  ///     required this.path,
  ///     this.backendPreference = HiveStorageBackendPreference.native,
  ///     this.boxName = 'cache-store',
  ///   });
  ///
  ///  @override
  ///   Future<void> initialiseStore() async {
  ///     Hive.init(path, backendPreference: backendPreference);
  ///     _store = await Hive.openBox(boxName);
  ///   }
  ///
  /// // rest of store overrides
  /// ```
  Future<void> initialiseStore();

  /// contract requirement for implementing saving a [CacheItem] to the
  /// [CacheStore], refer to [InMemoryCacheStore] or [HiveCacheStore]
  /// for usage examples
  Future<void> saveCacheItem(CacheItem item);

  /// contract requirement for implementing getting a [CacheItem] from the
  /// [CacheStore]. Returns a [FutureOr<CacheItem>],
  /// null when the [key] doesn't exist in the store else a [CacheItem],
  /// operation is a FutureOr since some operations can be synchronous like
  /// [InMemoryCacheStore]
  FutureOr<CacheItem?> getCacheItem(String key);

  /// contract requirement for implementing invalidating a [CacheItem] with [key]
  /// from the store. A simple operation that can be done by
  /// setting [CacheItem] persistentDuration to -[Duration] ago
  Future<void> invalidateCacheItem(String key);

  /// contract requirement for implementing invalidate the entire [CacheStore].
  /// In simple implementations, this clears the private storage mechanism
  /// like clearing [Map _store] in [InMemoryCacheStore]
  Future<void> invalidateCache();

  /// contract requirement for implementing checking if the [CacheStore]
  /// contains a certain [key]. For example in [InMemoryCacheStore] which
  /// uses a Map
  /// ```dart
  /// final class InMemoryCacheStore implements CacheStore {
  ///   InMemoryCacheStore();
  ///
  ///   late final Map<String, String> _store;
  ///
  /// @override
  ///   bool containsKey(String key) {
  ///     return _store.containsKey(key);
  ///   }
  /// // rest of store overrides
  ///
  /// ```
  bool containsKey(String key);

  /// contract requirement for closing the cache store
  /// helpful to allow stores be closed safely to prevent memory leaks.
  /// When implemented, the client should have to reinitialise the store to read
  /// its content
  FutureOr<void> close();
}
