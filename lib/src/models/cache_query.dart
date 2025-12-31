class CacheQuery {
  final Map<String, dynamic> where;
  final List<OrderBy> orderBy;
  final int? limit;
  final int? offset;
  final List<String>? fields;

  const CacheQuery({
    this.where = const {},
    this.orderBy = const [],
    this.limit,
    this.offset,
    this.fields,
  });

  CacheQuery copyWith({
    Map<String, dynamic>? where,
    List<OrderBy>? orderBy,
    int? limit,
    int? offset,
    List<String>? fields,
  }) {
    return CacheQuery(
      where: where ?? this.where,
      orderBy: orderBy ?? this.orderBy,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      fields: fields ?? this.fields,
    );
  }
}
class OrderBy {
  final String field;
  final bool descending;

  const OrderBy(this.field, {this.descending = false});
}