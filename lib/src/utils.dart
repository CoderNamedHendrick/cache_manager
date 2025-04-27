final class CacheManagerUtils {
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
