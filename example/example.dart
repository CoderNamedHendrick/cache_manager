import 'package:cache_manager_plus/cache_manager_plus.dart';

void main() async {
  await CacheManager.init(store: InMemoryCacheStore());

  CacheManager.instance.set(CacheItem.ephemeral(key: 'k', data: 'Hello world'));

  print((await CacheManager.instance.get('k'))?.data);
}
