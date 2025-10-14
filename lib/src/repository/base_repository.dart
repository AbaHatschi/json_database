import '../core/database_model.dart';
import '../operations/crud_operations.dart';
import '../operations/query_builder.dart';

/// Abstract base repository for MVVM patterns
/// Each model gets its own repository that inherits from this class
abstract class BaseRepository<T extends DatabaseModel> {
  BaseRepository(this.tableName, {String databaseName = 'database'})
    : _crud = CrudOperations(databaseName: databaseName) {
    // Only create table if it doesn't exist (preserve existing data)
    if (!_crud.tableExists(tableName)) {
      _crud.createTable(tableName);
    }
  }

  final CrudOperations _crud;
  final String tableName;

  // Abstract methods - must be implemented
  /// Converts JSON to model
  T fromJson(Map<String, dynamic> json);

  /// Converts model to JSON (usually done by the model itself)
  Map<String, dynamic> toJson(T model) => model.toJson();

  // CRUD Operations

  /// Creates a new record
  Future<T> create(T model) async {
    return _crud.create<T>(tableName, model);
  }

  /// Finds all records
  List<T> findAll() {
    return _crud
        .findAll(tableName)
        .map((Map<String, dynamic> json) => fromJson(json))
        .toList();
  }

  /// Finds a record by ID
  T? findById(int id) {
    final Map<String, dynamic>? json = _crud.findById(tableName, id);
    return json != null ? fromJson(json) : null;
  }

  /// Finds records by conditions
  List<T> findWhere(Map<String, dynamic> conditions) {
    return _crud
        .findWhere(tableName, conditions)
        .map((Map<String, dynamic> json) => fromJson(json))
        .toList();
  }

  /// Finds the first record that matches a condition
  T? findFirst(Map<String, dynamic> conditions) {
    final Map<String, dynamic>? json = _crud.findFirst(tableName, conditions);
    return json != null ? fromJson(json) : null;
  }

  /// Updates a model
  Future<T> update(T model) async {
    return _crud.updateModel<T>(tableName, model);
  }

  /// Updates records by ID
  Future<bool> updateById(int id, Map<String, dynamic> data) async {
    return _crud.updateById(tableName, id, data);
  }

  /// Deletes a model
  Future<bool> delete(T model) async {
    return _crud.deleteModel<T>(tableName, model);
  }

  /// Deletes a record by ID
  Future<bool> deleteById(int id) async {
    return _crud.deleteById(tableName, id);
  }

  /// Deletes all records
  Future<int> deleteAll() async {
    return _crud.deleteAll(tableName);
  }

  // Query Builder Support

  /// Creates a query builder for advanced queries
  QueryBuilder query() {
    return QueryBuilder(_crud.findAll(tableName));
  }

  /// Advanced search with query builder
  List<T> search(QueryBuilder Function(QueryBuilder) builder) {
    final List<Map<String, dynamic>> results = builder(query()).get();
    return results.map((Map<String, dynamic> json) => fromJson(json)).toList();
  }

  // Utility Methods

  /// Counts all records
  int count() {
    return _crud.count(tableName);
  }

  /// Counts records with conditions
  int countWhere(Map<String, dynamic> conditions) {
    return _crud.count(tableName, where: conditions);
  }

  /// Checks if records exist
  bool exists(Map<String, dynamic> conditions) {
    return _crud.exists(tableName, conditions);
  }

  /// Checks if a record with ID exists
  bool existsById(int id) {
    return exists(<String, dynamic>{'id': id});
  }

  /// Returns the first model (or null)
  T? first() {
    final List<T> models = findAll();
    return models.isNotEmpty ? models.first : null;
  }

  /// Returns the last model (or null)
  T? last() {
    final List<T> models = findAll();
    return models.isNotEmpty ? models.last : null;
  }

  // Batch Operations

  /// Creates multiple records
  Future<List<T>> createMany(List<T> models) async {
    final List<T> results = <T>[];
    for (final T model in models) {
      results.add(await create(model));
    }
    return results;
  }

  /// Deletes multiple records by IDs
  Future<int> deleteByIds(List<int> ids) async {
    int deletedCount = 0;
    for (final int id in ids) {
      if (await deleteById(id)) {
        deletedCount++;
      }
    }
    return deletedCount;
  }

  // Advanced Queries

  /// Paginated search
  List<T> paginate(int page, int pageSize) {
    return search((QueryBuilder query) => query.paginate(page, pageSize));
  }

  /// Sorted search
  List<T> orderBy(String field, {bool descending = false}) {
    return search(
      (QueryBuilder query) =>
          descending ? query.orderByDesc(field) : query.orderBy(field),
    );
  }

  /// Searches with LIKE
  List<T> searchByField(String field, String searchTerm) {
    return search(
      (QueryBuilder query) => query.whereOperator(field, 'like', searchTerm),
    );
  }
}
