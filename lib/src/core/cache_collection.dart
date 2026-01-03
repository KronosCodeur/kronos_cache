import 'package:awesome_logger/awesome_logger.dart';
import 'package:rxdart/rxdart.dart';

import '../adapters/cache_adapter.dart';
import '../models/cache_entry.dart';
import 'cache_config.dart';
import 'cache_query_builder.dart';

class CacheCollection {
  final String name;
  final CacheAdapter adapter;
  final CacheConfig config;
  final Duration? ttl;
  final EncryptionConfig? encryption;

  final BehaviorSubject<List<Map<String, dynamic>>> _controller =
  BehaviorSubject.seeded([]);

  CacheCollection({
    required this.name,
    required this.adapter,
    required this.config,
    this.ttl,
    this.encryption,
  });

  Future<void> create(String key, Map<String, dynamic> value, {
    Duration? ttl,
    Map<String, dynamic>? metadata,
  }) async {
    AwesomeLogger.database('Creating entry: $name/$key');
    AwesomeLogger.startTimer('create_$name');

    try {
      await adapter.set(
        name,
        key,
        value,
        ttl: ttl ?? this.ttl ?? config.ttl,
        metadata: metadata,
      );

      AwesomeLogger.stopTimer('create_$name');
      AwesomeLogger.success('Entry created: $name/$key');

      _notifyChanged();
    } catch (e, stack) {
      AwesomeLogger.stopTimer('create_$name');
      AwesomeLogger.error('Failed to create entry', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> post(String path, Map<String, dynamic> value, {
    Duration? ttl,
  }) async {
    final key = path.startsWith('/') ? path.substring(1) : path;
    await create(key, value, ttl: ttl);
  }

  Future<Map<String, dynamic>?> get(String key) async {
    AwesomeLogger.database('Getting entry: $name/$key');

    try {
      final data = await adapter.get(name, key);

      if (data != null) {
        AwesomeLogger.success('Entry found: $name/$key');
      } else {
        AwesomeLogger.info('Entry not found: $name/$key');
      }

      return data;
    } catch (e, stack) {
      AwesomeLogger.error('Failed to get entry', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> update(String key, Map<String, dynamic> updates) async {
    AwesomeLogger.database('Updating entry: $name/$key');

    try {
      await adapter.update(name, key, updates);
      AwesomeLogger.success('Entry updated: $name/$key');

      _notifyChanged();
    } catch (e, stack) {
      AwesomeLogger.error('Failed to update entry', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> put(String path, Map<String, dynamic> value) async {
    final key = path.startsWith('/') ? path.substring(1) : path;
    await update(key, value);
  }

  Future<void> patch(String path, Map<String, dynamic> updates) async {
    final key = path.startsWith('/') ? path.substring(1) : path;
    await update(key, updates);
  }

  Future<void> delete(String key) async {
    AwesomeLogger.database('Deleting entry: $name/$key');

    try {
      await adapter.delete(name, key);
      AwesomeLogger.success('Entry deleted: $name/$key');

      _notifyChanged();
    } catch (e, stack) {
      AwesomeLogger.error('Failed to delete entry', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<bool> exists(String key) async {
    return await adapter.exists(name, key);
  }

  Future<void> bulkCreate(
      List<Map<String, dynamic>> items, {
        Duration? ttl,
      }) async {
    AwesomeLogger.database('Bulk creating ${items.length} items in $name');
    AwesomeLogger.startTimer('bulk_create_$name');

    try {
      final entries = items.map((item) {
        final key = item['key'] as String;
        final value = item['value'] as Map<String, dynamic>;

        return CacheEntry(
          key: key,
          value: value,
          createdAt: DateTime.now(),
          expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
        );
      }).toList();

      await adapter.bulkSet(name, entries);

      AwesomeLogger.stopTimer('bulk_create_$name');
      AwesomeLogger.success('Bulk create complete: ${items.length} items');

      _notifyChanged();
    } catch (e, stack) {
      AwesomeLogger.stopTimer('bulk_create_$name');
      AwesomeLogger.error('Bulk create failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> bulkUpsert(
      List<Map<String, dynamic>> items, {
        Duration? ttl,
      }) async {
    await bulkCreate(items, ttl: ttl);
  }

  Future<void> bulkDelete(List<String> keys) async {
    AwesomeLogger.database('Bulk deleting ${keys.length} keys from $name');

    try {
      await adapter.bulkDelete(name, keys);
      AwesomeLogger.success('Bulk delete complete: ${keys.length} keys');

      _notifyChanged();
    } catch (e, stack) {
      AwesomeLogger.error('Bulk delete failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    AwesomeLogger.database('Getting all entries from $name');

    try {
      final data = await adapter.getAll(name);
      AwesomeLogger.success('Retrieved ${data.length} entries from $name');
      return data;
    } catch (e, stack) {
      AwesomeLogger.error('Failed to get all entries', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<List<String>> getKeys() async {
    return await adapter.getKeys(name);
  }

  CacheQueryBuilder where(
      String field, {
        dynamic isEqualTo,
        dynamic isNotEqualTo,
        dynamic isLessThan,
        dynamic isLessThanOrEqualTo,
        dynamic isGreaterThan,
        dynamic isGreaterThanOrEqualTo,
        List? isIn,
        bool? isNull,
      }) {
    return CacheQueryBuilder(this).where(
      field,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      isIn: isIn,
      isNull: isNull,
    );
  }

  CacheQueryBuilder orderBy(String field, {bool descending = false}) {
    return CacheQueryBuilder(this).orderBy(field, descending: descending);
  }

  CacheQueryBuilder limit(int count) {
    return CacheQueryBuilder(this).limit(count);
  }

  CacheQueryBuilder search(String query, {List<String>? fields}) {
    return CacheQueryBuilder(this).search(query, fields: fields);
  }

  Stream<List<Map<String, dynamic>>> stream() {
    getAll().then((data) => _controller.add(data));

    return _controller.stream;
  }

  Stream<Map<String, dynamic>?> watch(String key) {
    return _controller.stream.map((items) {
      try {
        return items.firstWhere((item) => item['id'] == key);
      } catch (e) {
        return null;
      }
    });
  }

  void _notifyChanged() {
    getAll().then((data) => _controller.add(data));
  }

  Future<void> clear() async {
    AwesomeLogger.warning('Clearing collection: $name');

    try {
      await adapter.clearCollection(name);
      AwesomeLogger.success('Collection cleared: $name');

      _notifyChanged();
    } catch (e, stack) {
      AwesomeLogger.error('Failed to clear collection', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<bool> isExpired(String key) async {
    try {
      final data = await get(key);
      if (data == null) {
        AwesomeLogger.warning('Key not found: $name/$key');
        return true;
      }

      final metadata = await adapter.getMetadata(name, key);
      if (metadata == null) return true;

      final expiresAt = metadata['expiresAt'];
      if (expiresAt == null) {
        return false;
      }

      final expirationDate = DateTime.parse(expiresAt);
      final isExpired = DateTime.now().isAfter(expirationDate);

      if (isExpired) {
        AwesomeLogger.warning('Cache expired: $name/$key');
      } else {
        AwesomeLogger.success('Cache valid: $name/$key');
      }

      return isExpired;
    } catch (e) {
      AwesomeLogger.error('Error checking expiration', error: e);
      return true;
    }
  }

  Future<Map<String, dynamic>?> getMetadata(String key) async {
    return await adapter.getMetadata(name, key);
  }

  Future<void> updateMetadata(String key, Map<String, dynamic> metadata) async {
    await adapter.updateMetadata(name, key, metadata);
  }

  void dispose() {
    _controller.close();
  }

  Future<T> getOrFetch<T>(
      String key, {
        required Future<T> Function() fetcher,
        required T Function(Map<String, dynamic>) fromJson,
        required Map<String, dynamic> Function(T) toJson,
        Duration? ttl,
      }) async {
    AwesomeLogger.info('Get or fetch: $name/$key');

    final cached = await get(key);
    if (cached != null) {
      AwesomeLogger.success('Cache hit: $name/$key');
      return fromJson(cached);
    }

    AwesomeLogger.network('Cache miss, fetching: $name/$key');
    final data = await fetcher();

    await create(key, toJson(data), ttl: ttl);

    return data;
  }
}