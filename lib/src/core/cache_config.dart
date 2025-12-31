import '../adapters/cache_adapter.dart';

class CacheConfig {
  final CacheAdapter adapter;

  final Duration? ttl;

  final int maxSize;

  final bool autoCleanup;

  final Duration cleanupInterval;

  final EncryptionConfig? encryption;

  final VoidCallback? onInit;

  final VoidCallback? onDispose;

  const CacheConfig({
    required this.adapter,
    this.ttl,
    this.maxSize = 0,
    this.autoCleanup = true,
    this.cleanupInterval = const Duration(hours: 1),
    this.encryption,
    this.onInit,
    this.onDispose,
  });

  factory CacheConfig.development({
    required CacheAdapter adapter,
    EncryptionConfig? encryption,
  }) {
    return CacheConfig(
      adapter: adapter,
      ttl: Duration(hours: 24),
      maxSize: 100 * 1024 * 1024,
      autoCleanup: true,
      encryption: encryption,
    );
  }

  factory CacheConfig.production({
    required CacheAdapter adapter,
    EncryptionConfig? encryption,
  }) {
    return CacheConfig(
      adapter: adapter,
      ttl: Duration(hours: 6),
      maxSize: 50 * 1024 * 1024,
      autoCleanup: true,
      cleanupInterval: Duration(minutes: 30),
      encryption: encryption ?? EncryptionConfig(enabled: true),
    );
  }
}

class EncryptionConfig {
  final bool enabled;

  final String? key;

  final EncryptionAlgorithm algorithm;

  final bool encryptKeys;

  const EncryptionConfig({
    this.enabled = false,
    this.key,
    this.algorithm = EncryptionAlgorithm.aes256,
    this.encryptKeys = false,
  });

  factory EncryptionConfig.secure(String key) {
    return EncryptionConfig(
      enabled: true,
      key: key,
      algorithm: EncryptionAlgorithm.aes256,
      encryptKeys: true,
    );
  }
}

enum EncryptionAlgorithm {
  aes256,
  aes128,
}

typedef VoidCallback = void Function();