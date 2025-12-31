import 'package:flutter/material.dart';

class CacheBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, Object error)? error;

  const CacheBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (error != null) {
            return error!(context, snapshot.error!);
          }
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          if (loading != null) {
            return loading!(context);
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return builder(context, snapshot.data as T);
      },
    );
  }
}

class CacheFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const CacheFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CacheBuilder<T>(
      future: future,
      builder: builder,
      loading: loadingWidget != null ? (_) => loadingWidget! : null,
      error: errorWidget != null ? (_, _) => errorWidget! : null,
    );
  }
}
