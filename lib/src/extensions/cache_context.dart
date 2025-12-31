import 'package:flutter/widgets.dart';

import '../core/cache_collection.dart';
import '../kronos_cache.dart';

extension CacheContext on BuildContext {
  CacheContextInstance get cache => CacheContextInstance(this);
}

class CacheContextInstance {
  final BuildContext context;

  CacheContextInstance(this.context);

  CacheCollection collection(String name) {
    return KronosCache.collection(name);
  }

  Future<void> set(
      String collection,
      String key,
      Map<String, dynamic> value,
      ) async {
    await KronosCache.collection(collection).create(key, value);
  }

  Future<Map<String, dynamic>?> get(String collection, String key) async {
    return await KronosCache.collection(collection).get(key);
  }

  Future<void> delete(String collection, String key) async {
    await KronosCache.collection(collection).delete(key);
  }

  Future<bool> exists(String collection, String key) async {
    return await KronosCache.collection(collection).exists(key);
  }

  Stream<List<Map<String, dynamic>>> watch(String collection) {
    return KronosCache.collection(collection).stream();
  }
}