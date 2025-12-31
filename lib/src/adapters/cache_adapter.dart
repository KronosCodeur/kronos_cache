import '../models/cache_entry.dart';

abstract class CacheAdapter {
  Future<void> initialize();

  Future<void> close();

  Future<Map<String, dynamic>?> get(String collection, String key);

  Future<void> set(
      String collection,
      String key,
      Map<String, dynamic> value, {
        Duration? ttl,
        Map<String, dynamic>? metadata,
      });

  Future<void> delete(String collection, String key);

  Future<bool> exists(String collection, String key);

  Future<List<Map<String, dynamic>>> getAll(String collection);

  Future<List<String>> getKeys(String collection);

  Future<void> clearCollection(String collection);

  Future<void> clear();

  Future<int> getSize();

  Future<void> bulkSet(
      String collection,
      List<CacheEntry> entries,
      );

  Future<void> bulkDelete(String collection, List<String> keys);

  Future<List<Map<String, dynamic>>> query(
      String collection,
      Map<String, dynamic> queryParams,
      );

  Future<void> update(
      String collection,
      String key,
      Map<String, dynamic> updates,
      );

  Future<Map<String, dynamic>?> getMetadata(String collection, String key);

  Future<void> updateMetadata(
      String collection,
      String key,
      Map<String, dynamic> metadata,
      );
}