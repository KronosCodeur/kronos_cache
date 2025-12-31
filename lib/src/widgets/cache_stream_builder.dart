import 'package:flutter/material.dart';

class CacheStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, Object error)? error;
  final T? initialData;

  const CacheStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loading,
    this.error,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
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
          if (!snapshot.hasData) {
            if (loading != null) {
              return loading!(context);
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return builder(context, snapshot.data as T);
      },
    );
  }
}