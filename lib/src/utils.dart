/// provides [CacheManager] utility methods to help with orchestrating
/// the manager in different contexts, for example
/// [composeKeyFromUrl] being used to compose a [CacheItem] key from a
/// given url
final class CacheManagerUtils {
  const CacheManagerUtils._();

  /// returns key intended to be used as a [CacheItem] key from a http url,
  /// it takes the url [path], a [requestMethod] and an optional [queryParams]
  static String composeKeyFromUrl(
    String path, {
    required String requestMethod,
    Map<String, dynamic>? queryParams,
  }) {
    return '$requestMethod:$path${queryParams?.queryString ?? ''}';
  }
}

extension on Map<String, dynamic> {
  String get queryString {
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      if (i > 0) buffer.write('&');
      final entry = entries.elementAt(i);
      buffer.write('${entry.key}=${entry.value}');
    }

    if (buffer.toString().isEmpty) return '';
    return '?${buffer.toString()}';
  }
}
