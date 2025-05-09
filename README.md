# Cache Manager Plus 📚

A Dart package for managing cache with support for multiple storage backends. The `CacheManager` provides an easy-to-use
API for caching data, with features like ephemeral and persistent caching, cache invalidation, and support for custom
storage implementations.

[![codecov](https://codecov.io/gh/CoderNamedHendrick/cache_manager/graph/badge.svg?token=FWovoPM26n)](https://codecov.io/gh/CoderNamedHendrick/cache_manager)
[![Test](https://github.com/CoderNamedHendrick/cache_manager/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/CoderNamedHendrick/cache_manager/actions/workflows/ci.yaml)
[![pub package](https://img.shields.io/pub/v/cache_manager_plus.svg?label=Version&style=flat)][pub]
[![Stars](https://img.shields.io/github/stars/codernamedhendrick/cache_manager?label=Stars&style=flat)][repo]
[![Watchers](https://img.shields.io/github/watchers/codernamedhendrick/cache_manager?label=Watchers&style=flat)][repo]

[![GitHub issues](https://img.shields.io/github/issues/codernamedhendrick/cache_manager?label=Issues&style=flat)][issues]
[![GitHub License](https://img.shields.io/github/license/codernamedhendrick/cache_manager?label=Licence&style=flat)][license]

## Table of content

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Features 🧪

- **Ephemeral and Persistent Caching**: Cache data with a specific expiration or as temporary data.
- **Multiple Storage Backends**: Use in-memory storage, Hive-based storage, or implement your own custom `CacheStore`.
- **Cache Invalidation**: Invalidate specific cache items or clear the entire cache.
- **Singleton Access**: Manage cache through a singleton `CacheManager` instance.
- **Customizable**: Extend the `CacheStore` interface to create your own storage backends.
- **Utils**: Find CacheManagerPlus utilities as a pub package [here](https://pub.dev/packages/cache_manager_plus_utils).
  Includes different CacheStore implementations and other utility functions

## Installation 🏗️

To use this package, add it to your `pubspec.yaml` file:

```yaml
dependencies:
  cache_manager_plus: ^1.0.0
 ```

Install by running:

```console
dart pub add cache_manager_plus
```

## Usage 🔧

Initializing the CacheManager

You can initialize the CacheManager with a single store or multiple stores:

```dart
import 'package:cache_manager_plus/cache_manager_plus.dart';

void main() async {
  // Single store mode
  await CacheManager.init(store: InMemoryCacheStore());

  // Multiple stores mode
  await CacheManager.init(
    stores: [InMemoryCacheStore()],
  );
}
```

Adding and Retrieving Cache Items

```dart
import 'package:cache_manager/cache_manager.dart';

void main() async {
  final cacheManager = CacheManager.instance;

  // Add a persistent cache item
  await cacheManager.set(
    CacheItem.persistent(
      key: 'user_profile',
      data: {'name': 'John Doe', 'age': 30},
      duration: Duration(days: 7),
    ),
  );

  // Retrieve the cache item
  final item = await cacheManager.get('user_profile');
  if (item != null && item.isValid) {
    print('Cached data: ${item.data}');
  }
}
```

Invalidating Cache

```dart
import 'package:cache_manager/cache_manager.dart';

void main() async {
  final cacheManager = CacheManager.instance;

  // Invalidate a specific cache item
  await cacheManager.invalidateCacheItem('user_profile');

  // Invalidate all cache items
  await cacheManager.invalidateCache();
}
```

## License

This project is licensed under the MIT License—see the [LICENSE](LICENSE) file for details

## Additional information

For more details, visit the [repository](https://github.com/CoderNamedHendrick/cache_manager)
and [example tests](https://github.com/CoderNamedHendrick/cache_manager/blob/main/test/cache_manager_test.dart).
Contributions, issues,
and feature requests are welcome. See the [issue tracker](https://github.com/CoderNamedHendrick/cache_manager/issues)
for more information.

## 🤓 Developer(s)

[<img src="https://github.com/CoderNamedHendrick.png" width="180" />](https://github.com/CoderNamedHendrick)

#### **Sebastine Odeh**

[![GitHub: codernamedhendrick](https://img.shields.io/badge/codernamedhendrick-EFF7F6?logo=GitHub&logoColor=333&link=https://www.github.com/codernamedhendrick)][github]
[![Linkedin: SebastineOdeh](https://img.shields.io/badge/SebastineOdeh-EFF7F6?logo=LinkedIn&logoColor=blue&link=https://www.linkedin.com/in/sebastine-odeh-1081a318b/)][linkedin]
[![Twitter: h3ndrick_](https://img.shields.io/badge/h3ndrick__-EFF7F6?logo=X&logoColor=333&link=https://x.com/H3ndrick_)][twitter]
[![Gmail: sebastinesoacatp@gmail.com](https://img.shields.io/badge/sebastinesoacatp@gmail.com-EFF7F6?logo=Gmail&link=mailto:sebastinesoacatp@gmail.com)][gmail]

[pub]: https://pub.dev/packages/cache_manager

[repo]: https://github.com/CoderNamedHendrick/cache_manager

[issues]: https://github.com/CoderNamedHendrick/cache_manager/issues

[license]: https://github.com/CoderNamedHendrick/cache_manager/blob/main/LICENSE

[github]: https://www.github.com/codernamedhendrick

[linkedin]: https://www.linkedin.com/in/sebastine-odeh-1081a318b

[twitter]: https://x.com/H3ndrick_