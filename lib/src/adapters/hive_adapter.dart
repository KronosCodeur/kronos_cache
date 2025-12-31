import 'package:hive_flutter/hive_flutter.dart';
import 'package:awesome_logger/awesome_logger.dart';

import '../models/cache_entry.dart';
import 'cache_adapter.dart';

class HiveAdapter implements CacheAdapter {
  final Map<String, Box> _boxes = {};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    AwesomeLogger.database('Initializing Hive adapter');

    try {
      await Hive.initFlutter();
      _initialized = true;
      AwesomeLogger.success('Hive adapter initialized');
    } catch (e, stack) {
      AwesomeLogger.error(
        'Failed to initialize Hive',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    AwesomeLogger.database('Closing Hive adapter');

    for (var box in _boxes.values) {
      await box.close();
    }
    _boxes.clear();

    AwesomeLogger.success('Hive adapter closed');
  }

  Future<Box> _getBox(String collection) async {
    if (_boxes.containsKey(collection)) {
      return _boxes[collection]!;
    }

    AwesomeLogger.database('Opening Hive box: $collection');

    try {
      final box = await Hive.openBox(collection);
      _boxes[collection] = box;
      return box;
    } catch (e, stack) {
      AwesomeLogger.error(
        'Failed to open box: $collection',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> get(String collection, String key) async {
    final box = await _getBox(collection);
    final entry = box.get(key);

    if (entry == null) return null;

    if (entry['expiresAt'] != null) {
      final expiresAt = DateTime.parse(entry['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        await delete(collection, key);
        return null;
      }
    }

    return Map<String, dynamic>.from(entry['data']);
  }

  @override
  Future<void> set(
      String collection,
      String key,
      Map<String, dynamic> value, {
        Duration? ttl,
        Map<String, dynamic>? metadata,
      }) async {
    final box = await _getBox(collection);

    final entry = {
      'data': value,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': ttl != null
          ? DateTime.now().add(ttl).toIso8601String()
          : null,
      'metadata': metadata ?? {},
    };

    await box.put(key, entry);

    AwesomeLogger.database('Cached: $collection/$key');
  }

  @override
  Future<void> delete(String collection, String key) async {
    final box = await _getBox(collection);
    await box.delete(key);

    AwesomeLogger.database('Deleted: $collection/$key');
  }

  @override
  Future<bool> exists(String collection, String key) async {
    final box = await _getBox(collection);
    return box.containsKey(key);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final box = await _getBox(collection);
    final results = <Map<String, dynamic>>[];

    for (var key in box.keys) {
      final data = await get(collection, key.toString());
      if (data != null) {
        results.add(data);
      }
    }

    return results;
  }

  @override
  Future<List<String>> getKeys(String collection) async {
    final box = await _getBox(collection);
    return box.keys.map((k) => k.toString()).toList();
  }

  @override
  Future<void> clearCollection(String collection) async {
    final box = await _getBox(collection);
    await box.clear();

    AwesomeLogger.database('Cleared collection: $collection');
  }

  @override
  Future<void> clear() async {
    AwesomeLogger.warning('Clearing all Hive data');

    for (var collection in _boxes.keys.toList()) {
      await clearCollection(collection);
    }
  }

  @override
  Future<int> getSize() async {
    int totalSize = 0;

    for (var box in _boxes.values) {
      totalSize += box.length * 1000;
    }

    return totalSize;
  }

  @override
  Future<void> bulkSet(String collection, List<CacheEntry> entries) async {
    final box = await _getBox(collection);

    AwesomeLogger.database('Bulk setting ${entries.length} entries in $collection');
    AwesomeLogger.startTimer('bulk_set_$collection');

    await box.putAll({
      for (var entry in entries)
        entry.key: {
          'data': entry.value,
          'createdAt': entry.createdAt.toIso8601String(),
          'expiresAt': entry.expiresAt?.toIso8601String(),
          'metadata': entry.metadata,
        }
    });

    AwesomeLogger.stopTimer('bulk_set_$collection');
    AwesomeLogger.success('Bulk set complete: ${entries.length} entries');
  }

  @override
  Future<void> bulkDelete(String collection, List<String> keys) async {
    final box = await _getBox(collection);

    AwesomeLogger.database('Bulk deleting ${keys.length} keys from $collection');

    await box.deleteAll(keys);

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

    AwesomeLogger.database('Updated: $collection/$key');
  }

  @override
  Future<Map<String, dynamic>?> getMetadata(
      String collection,
      String key,
      ) async {
    final box = await _getBox(collection);
    final entry = box.get(key);

    if (entry == null) return null;

    return Map<String, dynamic>.from(entry['metadata'] ?? {});
  }

  @override
  Future<void> updateMetadata(
      String collection,
      String key,
      Map<String, dynamic> metadata,
      ) async {
    final box = await _getBox(collection);
    final entry = box.get(key);

    if (entry == null) {
      throw StateError('Key $key not found in $collection');
    }

    entry['metadata'] = {
      ...entry['metadata'] ?? {},
      ...metadata,
    };

    await box.put(key, entry);

    AwesomeLogger.database('Updated metadata: $collection/$key');
  }
}