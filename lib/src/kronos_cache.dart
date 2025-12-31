import 'package:awesome_logger/awesome_logger.dart';

import 'adapters/cache_adapter.dart';
import 'core/cache_collection.dart';
import 'core/cache_config.dart';

class KronosCache {
  static CacheConfig? _config;
  static CacheAdapter? _adapter;
  static bool _initialized = false;
  static final Map<String, CacheCollection> _collections = {};

  static Future<void> initialize(CacheConfig config) async {
    if (_initialized) {
      AwesomeLogger.warning('KronosCache already initialized');
      return;
    }

    AwesomeLogger.info('Initializing Kronos Cache...');
    AwesomeLogger.startTimer('kronos_cache_init');

    try {
      _config = config;
      _adapter = config.adapter;

      await _adapter!.initialize();

      _initialized = true;

      AwesomeLogger.stopTimer('kronos_cache_init');
      AwesomeLogger.success('Kronos Cache initialized successfully');

      config.onInit?.call();
    } catch (e, stack) {
      AwesomeLogger.stopTimer('kronos_cache_init');
      AwesomeLogger.error(
        'Failed to initialize Kronos Cache',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  static CacheCollection collection(
      String name, {
        Duration? ttl,
        EncryptionConfig? encryption,
      }) {
    _ensureInitialized();

    if (_collections.containsKey(name)) {
      return _collections[name]!;
    }

    AwesomeLogger.debug('Creating collection: $name');

    final collection = CacheCollection(
      name: name,
      adapter: _adapter!,
      config: _config!,
      ttl: ttl,
      encryption: encryption,
    );

    _collections[name] = collection;
    return collection;
  }

  static CacheConfig get config {
    _ensureInitialized();
    return _config!;
  }

  static bool get isInitialized => _initialized;

  static Future<void> clearAll() async {
    _ensureInitialized();

    AwesomeLogger.warning('Clearing all cache data');
    AwesomeLogger.startTimer('clear_all_cache');

    try {
      await _adapter!.clear();

      AwesomeLogger.stopTimer('clear_all_cache');
      AwesomeLogger.success('All cache cleared');
    } catch (e, stack) {
      AwesomeLogger.stopTimer('clear_all_cache');
      AwesomeLogger.error('Failed to clear cache', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<void> dispose() async {
    if (!_initialized) return;

    AwesomeLogger.info('Disposing Kronos Cache');

    try {
      await _adapter!.close();
      _collections.clear();
      _initialized = false;

      AwesomeLogger.success('Kronos Cache disposed');
    } catch (e, stack) {
      AwesomeLogger.error('Failed to dispose cache', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<int> getSize() async {
    _ensureInitialized();
    return await _adapter!.getSize();
  }

  static Future<Map<String, dynamic>> getStats() async {
    _ensureInitialized();

    final size = await getSize();
    final collections = _collections.keys.toList();

    return {
      'size': size,
      'sizeFormatted': _formatBytes(size),
      'collections': collections,
      'collectionsCount': collections.length,
      'adapter': _adapter.runtimeType.toString(),
      'initialized': _initialized,
    };
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'KronosCache not initialized. Call KronosCache.initialize() first.',
      );
    }
  }
}