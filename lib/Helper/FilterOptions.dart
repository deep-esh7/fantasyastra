enum FilterOperator {
  equals,
  greaterThan,
  lessThan,
  whereIn,
  arrayContains
}

class QueryFilter {
  final String fieldName;
  final FilterOperator operator;
  final dynamic value;

  QueryFilter({
    required this.fieldName,
    required this.operator,
    required this.value,
  });

  @override
  String toString() => 'QueryFilter(field: $fieldName, operator: $operator, value: $value)';
}
