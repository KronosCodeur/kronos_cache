import 'package:awesome_logger/awesome_logger.dart';

import '../models/cache_entry.dart';
import 'cache_adapter.dart';

class MemoryAdapter implements CacheAdapter {
  final Map<String, Map<String, _MemoryEntry>> _storage = {};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    AwesomeLogger.database('Initializing Memory adapter');
    _initialized = true;
    AwesomeLogger.success('Memory adapter initialized');
  }

  @override
  Future<void> close() async {
    AwesomeLogger.database('Closing Memory adapter');
    _storage.clear();
    _initialized = false;
  }

  Map<String, _MemoryEntry> _getCollection(String collection) {
    if (!_storage.containsKey(collection)) {
      _storage[collection] = {};
    }
    return _storage[collection]!;
  }

  @override
  Future<Map<String, dynamic>?> get(String collection, String key) async {
    final coll = _getCollection(collection);
    final entry = coll[key];

    if (entry == null) return null;

    if (entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
      await delete(collection, key);
      return null;
    }

    return entry.data;
  }

  @override
  Future<void> set(
      String collection,
      String key,
      Map<String, dynamic> value, {
        Duration? ttl,
        Map<String, dynamic>? metadata,
      }) async {
    final coll = _getCollection(collection);

    coll[key] = _MemoryEntry(
      data: Map<String, dynamic>.from(value),
      createdAt: DateTime.now(),
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
      metadata: metadata ?? {},
    );

    AwesomeLogger.database('Cached in memory: $collection/$key');
  }

  @override
  Future<void> delete(String collection, String key) async {
    final coll = _getCollection(collection);
    coll.remove(key);

    AwesomeLogger.database('Deleted from memory: $collection/$key');
  }

  @override
  Future<bool> exists(String collection, String key) async {
    final coll = _getCollection(collection);
    return coll.containsKey(key);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final coll = _getCollection(collection);
    final results = <Map<String, dynamic>>[];

    final keys = coll.keys.toList();

    for (var key in keys) {
      final data = await get(collection, key);
      if (data != null) {
        results.add(data);
      }
    }

    return results;
  }

  @override
  Future<List<String>> getKeys(String collection) async {
    final coll = _getCollection(collection);
    return coll.keys.toList();
  }

  @override
  Future<void> clearCollection(String collection) async {
    _storage.remove(collection);
    AwesomeLogger.database('Cleared memory collection: $collection');
  }

  @override
  Future<void> clear() async {
    AwesomeLogger.warning('Clearing all memory data');
    _storage.clear();
  }

  @override
  Future<int> getSize() async {
    int totalSize = 0;

    for (var coll in _storage.values) {
      for (var entry in coll.values) {
        totalSize += entry.data.toString().length;
      }
    }

    return totalSize;
  }

  @override
  Future<void> bulkSet(String collection, List<CacheEntry> entries) async {
    final coll = _getCollection(collection);

    AwesomeLogger.database('Bulk setting ${entries.length} entries in memory');

    for (var entry in entries) {
      coll[entry.key] = _MemoryEntry(
        data: entry.value,
        createdAt: entry.createdAt,
        expiresAt: entry.expiresAt,
        metadata: entry.metadata,
      );
    }

    AwesomeLogger.success('Bulk set complete: ${entries.length} entries');
  }

  @override
  Future<void> bulkDelete(String collection, List<String> keys) async {
    final coll = _getCollection(collection);

    AwesomeLogger.database('Bulk deleting ${keys.length} keys from memory');

    for (var key in keys) {
      coll.remove(key);
    }

    AwesomeLogger.success('Bulk delete complete: ${keys.length} keys');
  }

  @override
  Future<List<Map<String, dynamic>>> query(
      String collection,
      Map<String, dynamic> queryParams,
      ) async {
    final all = await getAll(collection);

    return all.where((item) {
      for (var entry in queryParams.entries) {
        if (item[entry.key] != entry.value) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<void> update(
      String collection,
      String key,
      Map<String, dynamic> updates,
      ) async {
    final existing = await get(collection, key);
    if (existing == null) {
      throw StateError('Key $key not found in $collection');
    }

    final updated = Map<String, dynamic>.from(existing)..addAll(updates);
    await set(collection, key, updated);

    AwesomeLogger.database('Updated in memory: $collection/$key');
  }

  @override
  Future<Map<String, dynamic>?> getMetadata(
      String collection,
      String key,
      ) async {
    final coll = _getCollection(collection);
    final entry = coll[key];

    return entry?.metadata;
  }

  @override
  Future<void> updateMetadata(
      String collection,
      String key,
      Map<String, dynamic> metadata,
      ) async {
    final coll = _getCollection(collection);
    final entry = coll[key];

    if (entry == null) {
      throw StateError('Key $key not found in $collection');
    }

    entry.metadata = {
      ...entry.metadata,
      ...metadata,
    };

    AwesomeLogger.database('Updated metadata in memory: $collection/$key');
  }
}

class _MemoryEntry {
  Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? expiresAt;
  Map<String, dynamic> metadata;

  _MemoryEntry({
    required this.data,
    required this.createdAt,
    this.expiresAt,
    required this.metadata,
  });
}