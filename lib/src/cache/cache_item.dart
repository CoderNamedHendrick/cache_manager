import 'dart:convert';

final class CacheItem {
  final String key;
  final Object data;
  final DateTime expiry;

  const CacheItem._(this.key, this.data, this.expiry);

  /// This factory constructor is used for caching data that shouldn't persist
  /// so they're set to expired just as they're created by setting the expiry
  /// to the current time.
  factory CacheItem.ephemeral({
    required String key,
    required Object data,
  }) {
    return CacheItem._(key, data, DateTime.now());
  }

  /// This factory constructor is used to create cache items that will persist
  /// for the specified duration as soon as they're created.
  factory CacheItem.persistent({
    required String key,
    required Object data,
    required Duration duration,
  }) {
    return CacheItem._(key, data, DateTime.now().add(duration));
  }

  bool get isExpired => DateTime.now().isAfter(expiry);

  bool get isValid => !isExpired;

  bool get isInvalid => !isValid;

  String toCacheEntryString() {
    return jsonEncode({
      'expiry': expiry.toIso8601String(),
      'data': data,
    });
  }

  static CacheItem fromCacheEntryString(String entry, {required String key}) {
    final json = jsonDecode(entry);
    return CacheItem._(
      key,
      json['data'],
      DateTime.parse(json['expiry']),
    );
  }

  CacheItem copyWith({
    String? key,
    Object? data,
    DateTime? expiry,
    Duration? persistenceDuration,
  }) {
    return CacheItem._(
      key ?? this.key,
      data ?? this.data,
      switch ((expiry, persistenceDuration)) {
        (final expiry?, final persistenceDuration?) =>
          expiry.add(persistenceDuration),
        (final expiry?, null) => expiry,
        (null, final persistenceDuration?) =>
          DateTime.now().add(persistenceDuration),
        (null, null) => this.expiry,
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CacheItem &&
        other.key == key &&
        other.data == data &&
        other.expiry == expiry;
  }

  @override
  int get hashCode => key.hashCode ^ data.hashCode ^ expiry.hashCode;
}
