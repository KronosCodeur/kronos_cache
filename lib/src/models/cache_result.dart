class CacheResult<T> {
  final T? data;
  final bool success;
  final String? error;
  final DateTime timestamp;

  const CacheResult({
    this.data,
    required this.success,
    this.error,
    required this.timestamp,
  });

  factory CacheResult.success(T data) => CacheResult(
    data: data,
    success: true,
    timestamp: DateTime.now(),
  );

  factory CacheResult.failure(String error) => CacheResult(
    success: false,
    error: error,
    timestamp: DateTime.now(),
  );

  bool get isSuccess => success;
  bool get isFailure => !success;
}