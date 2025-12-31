import 'package:awesome_logger/awesome_logger.dart';

import 'cache_collection.dart';

class CacheQueryBuilder {
  final CacheCollection collection;
  final List<_WhereClause> _whereClauses = [];
  final List<_OrderByClause> _orderByClauses = [];
  int? _limitCount;
  int? _offsetCount;
  String? _searchQuery;
  List<String>? _searchFields;

  CacheQueryBuilder(this.collection);

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
    _whereClauses.add(_WhereClause(
      field: field,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      isIn: isIn,
      isNull: isNull,
    ));

    return this;
  }

  CacheQueryBuilder orderBy(String field, {bool descending = false}) {
    _orderByClauses.add(_OrderByClause(
      field: field,
      descending: descending,
    ));

    return this;
  }

  CacheQueryBuilder limit(int count) {
    _limitCount = count;
    return this;
  }

  CacheQueryBuilder offset(int count) {
    _offsetCount = count;
    return this;
  }

  CacheQueryBuilder search(String query, {List<String>? fields}) {
    _searchQuery = query;
    _searchFields = fields;
    return this;
  }

  Future<List<Map<String, dynamic>>> get() async {
    AwesomeLogger.debug('Executing query on ${collection.name}');
    AwesomeLogger.startTimer('query_${collection.name}');

    try {
      var results = await collection.getAll();

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        results = _applySearch(results);
      }

      for (var clause in _whereClauses) {
        results = _applyWhereClause(results, clause);
      }

      if (_orderByClauses.isNotEmpty) {
        results = _applyOrderBy(results);
      }

      if (_offsetCount != null && _offsetCount! > 0) {
        results = results.skip(_offsetCount!).toList();
      }

      if (_limitCount != null) {
        results = results.take(_limitCount!).toList();
      }

      AwesomeLogger.stopTimer('query_${collection.name}');
      AwesomeLogger.success('Query returned ${results.length} results');

      return results;
    } catch (e, stack) {
      AwesomeLogger.stopTimer('query_${collection.name}');
      AwesomeLogger.error('Query failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> stream() {
    return collection.stream().asyncMap((_) => get());
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> data) {
    if (_searchQuery == null || _searchQuery!.isEmpty) return data;

    final query = _searchQuery!.toLowerCase();

    return data.where((item) {
      if (_searchFields != null) {
        for (var field in _searchFields!) {
          final value = _getNestedValue(item, field);
          if (value != null &&
              value.toString().toLowerCase().contains(query)) {
            return true;
          }
        }
        return false;
      } else {
        return item.values.any((value) =>
        value != null && value.toString().toLowerCase().contains(query));
      }
    }).toList();
  }

  List<Map<String, dynamic>> _applyWhereClause(
      List<Map<String, dynamic>> data,
      _WhereClause clause,
      ) {
    return data.where((item) {
      final value = _getNestedValue(item, clause.field);

      if (clause.isNull != null) {
        return clause.isNull! ? value == null : value != null;
      }

      if (value == null) return false;

      if (clause.isEqualTo != null) {
        return value == clause.isEqualTo;
      }

      if (clause.isNotEqualTo != null) {
        return value != clause.isNotEqualTo;
      }

      if (clause.isLessThan != null) {
        return _compare(value, clause.isLessThan!) < 0;
      }

      if (clause.isLessThanOrEqualTo != null) {
        return _compare(value, clause.isLessThanOrEqualTo!) <= 0;
      }

      if (clause.isGreaterThan != null) {
        return _compare(value, clause.isGreaterThan!) > 0;
      }

      if (clause.isGreaterThanOrEqualTo != null) {
        return _compare(value, clause.isGreaterThanOrEqualTo!) >= 0;
      }

      if (clause.isIn != null) {
        return clause.isIn!.contains(value);
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _applyOrderBy(List<Map<String, dynamic>> data) {
    final sorted = List<Map<String, dynamic>>.from(data);

    sorted.sort((a, b) {
      for (var clause in _orderByClauses) {
        final aValue = _getNestedValue(a, clause.field);
        final bValue = _getNestedValue(b, clause.field);

        if (aValue == null && bValue == null) continue;
        if (aValue == null) return clause.descending ? -1 : 1;
        if (bValue == null) return clause.descending ? 1 : -1;

        final comparison = _compare(aValue, bValue);

        if (comparison != 0) {
          return clause.descending ? -comparison : comparison;
        }
      }

      return 0;
    });

    return sorted;
  }

  dynamic _getNestedValue(Map<String, dynamic> map, String key) {
    if (!key.contains('.')) {
      return map[key];
    }

    final keys = key.split('.');
    dynamic value = map;

    for (var k in keys) {
      if (value is! Map) return null;
      value = value[k];
      if (value == null) return null;
    }

    return value;
  }

  int _compare(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    }

    if (a is String && b is String) {
      return a.compareTo(b);
    }

    if (a is DateTime && b is DateTime) {
      return a.compareTo(b);
    }

    if (a is bool && b is bool) {
      return a == b ? 0 : (a ? 1 : -1);
    }

    return a.toString().compareTo(b.toString());
  }
}

class _WhereClause {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final List? isIn;
  final bool? isNull;

  _WhereClause({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.isIn,
    this.isNull,
  });
}

class _OrderByClause {
  final String field;
  final bool descending;

  _OrderByClause({
    required this.field,
    required this.descending,
  });
}