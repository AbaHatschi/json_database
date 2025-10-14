/// Query Builder for advanced database queries
/// Enables sorting, filtering and more
class QueryBuilder {
  QueryBuilder(List<Map<String, dynamic>> data) : _result = List<Map<String, dynamic>>.from(data);
  List<Map<String, dynamic>> _result;

  /// Filters by conditions (WHERE)
  QueryBuilder where(String field, dynamic value) {
    _result = _result
        .where((Map<String, dynamic> row) => row[field] == value)
        .toList();
    return this;
  }

  /// Filters by multiple conditions (AND)
  QueryBuilder whereAll(Map<String, dynamic> conditions) {
    _result = _result.where((Map<String, dynamic> row) {
      for (final MapEntry<String, dynamic> entry in conditions.entries) {
        if (row[entry.key] != entry.value) {
          return false;
        }
      }
      return true;
    }).toList();
    return this;
  }

  /// Filters by conditions with operators
  QueryBuilder whereOperator(String field, String operator, dynamic value) {
    _result = _result.where((Map<String, dynamic> row) {
      final dynamic fieldValue = row[field];

      switch (operator.toLowerCase()) {
        case '=':
        case '==':
          return fieldValue == value;
        case '!=':
        case '<>':
          return fieldValue != value;
        case '>':
          return _compareValues(fieldValue, value) > 0;
        case '>=':
          return _compareValues(fieldValue, value) >= 0;
        case '<':
          return _compareValues(fieldValue, value) < 0;
        case '<=':
          return _compareValues(fieldValue, value) <= 0;
        case 'like':
          return fieldValue.toString().toLowerCase().contains(
            value.toString().toLowerCase(),
          );
        case 'in':
          return value is List && value.contains(fieldValue);
        default:
          throw ArgumentError('Unknown operator: $operator');
      }
    }).toList();
    return this;
  }

  /// Compares two values for operators
  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return -1;
    }
    if (b == null) {
      return 1;
    }

    if (a is num && b is num) {
      return a.compareTo(b);
    }

    if (a is String && b is String) {
      return a.compareTo(b);
    }

    if (a is DateTime && b is DateTime) {
      return a.compareTo(b);
    }

    // Fallback: String-Comparison
    return a.toString().compareTo(b.toString());
  }

  /// Filters by range (BETWEEN)
  QueryBuilder whereBetween(String field, dynamic min, dynamic max) {
    _result = _result.where((Map<String, dynamic> row) {
      final dynamic value = row[field];
      return _compareValues(value, min) >= 0 && _compareValues(value, max) <= 0;
    }).toList();
    return this;
  }

  /// Filters by NULL values
  QueryBuilder whereNull(String field) {
    _result = _result
        .where((Map<String, dynamic> row) => row[field] == null)
        .toList();
    return this;
  }

  /// Filters by NOT NULL values
  QueryBuilder whereNotNull(String field) {
    _result = _result
        .where((Map<String, dynamic> row) => row[field] != null)
        .toList();
    return this;
  }

  /// Sorts ascending (ORDER BY ASC)
  QueryBuilder orderBy(String field) {
    _result.sort(
      (Map<String, dynamic> a, Map<String, dynamic> b) =>
          _compareValues(a[field], b[field]),
    );
    return this;
  }

  /// Sorts descending (ORDER BY DESC)
  QueryBuilder orderByDesc(String field) {
    _result.sort(
      (Map<String, dynamic> a, Map<String, dynamic> b) =>
          _compareValues(b[field], a[field]),
    );
    return this;
  }

  /// Sorts by multiple fields
  QueryBuilder orderByMultiple(List<Map<String, dynamic>> sorts) {
    _result.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      for (final Map<String, dynamic> sort in sorts) {
        final String field = sort['field'] as String;
        final bool desc = sort['desc'] as bool? ?? false;

        final int comparison = _compareValues(a[field], b[field]);
        if (comparison != 0) {
          return desc ? -comparison : comparison;
        }
      }
      return 0;
    });
    return this;
  }

  /// Limits the number of results (LIMIT)
  QueryBuilder limit(int count) {
    if (count > 0 && count < _result.length) {
      _result = _result.take(count).toList();
    }
    return this;
  }

  /// Skips results (OFFSET)
  QueryBuilder offset(int count) {
    if (count > 0 && count < _result.length) {
      _result = _result.skip(count).toList();
    }
    return this;
  }

  /// Pagination (LIMIT + OFFSET)
  QueryBuilder paginate(int page, int pageSize) {
    final int skip = (page - 1) * pageSize;
    return offset(skip).limit(pageSize);
  }

  /// Selects only certain fields (SELECT)
  QueryBuilder select(List<String> fields) {
    _result = _result.map((Map<String, dynamic> row) {
      final Map<String, dynamic> selected = <String, dynamic>{};
      for (final String field in fields) {
        if (row.containsKey(field)) {
          selected[field] = row[field];
        }
      }
      return selected;
    }).toList();
    return this;
  }

  /// Removes duplicates (DISTINCT)
  QueryBuilder distinct() {
    final Set<String> seen = <String>{};
    _result = _result.where((Map<String, dynamic> row) {
      final String key = row.toString();
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
    return this;
  }

  /// Groups by field (GROUP BY)
  Map<dynamic, List<Map<String, dynamic>>> groupBy(String field) {
    final Map<dynamic, List<Map<String, dynamic>>> groups =
        <dynamic, List<Map<String, dynamic>>>{};

    for (final Map<String, dynamic> row in _result) {
      final dynamic key = row[field];
      groups[key] ??= <Map<String, dynamic>>[];
      groups[key]!.add(row);
    }

    return groups;
  }

  /// Counts groupings
  Map<dynamic, int> countBy(String field) {
    final Map<dynamic, List<Map<String, dynamic>>> groups = groupBy(field);
    return groups.map(
      (dynamic key, List<Map<String, dynamic>> value) =>
          MapEntry<dynamic, int>(key, value.length),
    );
  }

  /// Returns the results
  List<Map<String, dynamic>> get() {
    return List<Map<String, dynamic>>.from(_result);
  }

  /// Returns the first result
  Map<String, dynamic>? first() {
    return _result.isNotEmpty ? _result.first : null;
  }

  /// Returns the last result
  Map<String, dynamic>? last() {
    return _result.isNotEmpty ? _result.last : null;
  }

  /// Counts the results
  int count() {
    return _result.length;
  }

  /// Checks if there are results
  bool isEmpty() {
    return _result.isEmpty;
  }

  /// Checks if there are not results
  bool isNotEmpty() {
    return _result.isNotEmpty;
  }

  /// Applies a custom function to the results
  QueryBuilder whereCustom(bool Function(Map<String, dynamic>) predicate) {
    _result = _result.where(predicate).toList();
    return this;
  }
}
