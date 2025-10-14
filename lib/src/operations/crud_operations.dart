import '../core/database_engine.dart';
import '../core/database_model.dart';

/// CRUD operations for the database
/// Provides a clean API for Create, Read, Update, Delete
class CrudOperations {
  CrudOperations({this.databaseName = 'database'});
  final DatabaseEngine _engine = DatabaseEngine.instance;
  final String databaseName;

  /// Creates a new record
  /// The model must implement DatabaseModel
  Future<T> create<T extends DatabaseModel>(String tableName, T model) async {
    final Map<String, dynamic> data = model.toJson();
    final Map<String, dynamic> result = await _engine.insert(
      tableName,
      data,
      databaseName: databaseName,
    );

    // Set ID back in model
    model.id = result['id'] as int;
    return model;
  }

  /// Creates a new record from Map
  Future<Map<String, dynamic>> createFromMap(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    return _engine.insert(tableName, data, databaseName: databaseName);
  }

  /// Searches all records of a table
  List<Map<String, dynamic>> findAll(String tableName) {
    return _engine.find(tableName);
  }

  /// Searches records with conditions
  List<Map<String, dynamic>> findWhere(
    String tableName,
    Map<String, dynamic> conditions,
  ) {
    return _engine.find(tableName, where: conditions);
  }

  /// Searches a record by ID
  Map<String, dynamic>? findById(String tableName, int id) {
    return _engine.findById(tableName, id);
  }

  /// Searches the first record that meets a condition
  Map<String, dynamic>? findFirst(
    String tableName,
    Map<String, dynamic> conditions,
  ) {
    final List<Map<String, dynamic>> results = findWhere(tableName, conditions);
    return results.isNotEmpty ? results.first : null;
  }

  /// Updates a model
  Future<T> updateModel<T extends DatabaseModel>(
    String tableName,
    T model,
  ) async {
    if (model.id == null) {
      throw ArgumentError('Model must have an ID to be updated');
    }

    final Map<String, dynamic> data = model.toJson();
    data.remove('id'); // Do not overwrite ID

    final int updated = await _engine.update(
      tableName,
      data,
      where: <String, dynamic>{'id': model.id},
      databaseName: databaseName,
    );

    if (updated == 0) {
      throw StateError('Dataset with ID ${model.id} not found');
    }

    return model;
  }

  /// Updates records based on conditions
  Future<int> updateWhere(
    String tableName,
    Map<String, dynamic> data,
    Map<String, dynamic> conditions,
  ) async {
    return _engine.update(
      tableName,
      data,
      where: conditions,
      databaseName: databaseName,
    );
  }

  /// Updates a record by ID
  Future<bool> updateById(
    String tableName,
    int id,
    Map<String, dynamic> data,
  ) async {
    final int updated = await updateWhere(tableName, data, <String, dynamic>{
      'id': id,
    });
    return updated > 0;
  }

  /// Deletes a model
  Future<bool> deleteModel<T extends DatabaseModel>(
    String tableName,
    T model,
  ) async {
    if (model.id == null) {
      throw ArgumentError('Model must have an ID to be deleted');
    }

    final int deleted = await _engine.delete(
      tableName,
      where: <String, dynamic>{'id': model.id},
      databaseName: databaseName,
    );

    return deleted > 0;
  }

  /// Deletes a record by ID
  Future<bool> deleteById(String tableName, int id) async {
    final int deleted = await _engine.delete(
      tableName,
      where: <String, dynamic>{'id': id},
      databaseName: databaseName,
    );

    return deleted > 0;
  }

  /// Deletes records based on conditions
  Future<int> deleteWhere(
    String tableName,
    Map<String, dynamic> conditions,
  ) async {
    return _engine.delete(
      tableName,
      where: conditions,
      databaseName: databaseName,
    );
  }

  /// Deletes all records of a table
  Future<int> deleteAll(String tableName) async {
    final List<Map<String, dynamic>> allData = findAll(tableName);
    if (allData.isEmpty) {
      return 0;
    }

    await _engine.dropTable(tableName, databaseName: databaseName);
    _engine.createTable(tableName);

    return allData.length;
  }

  /// Counts records in a table
  int count(String tableName, {Map<String, dynamic>? where}) {
    if (where == null) {
      return findAll(tableName).length;
    }
    return findWhere(tableName, where).length;
  }

  /// Checks if records exist
  bool exists(String tableName, Map<String, dynamic> conditions) {
    return findFirst(tableName, conditions) != null;
  }

  /// Creates a table (if it doesn't exist)
  void createTable(String tableName) {
    _engine.createTable(tableName);
  }

  /// Checks if a table exists
  bool tableExists(String tableName) {
    return _engine.tableExists(tableName);
  }

  /// Deletes a table
  Future<void> dropTable(String tableName) async {
    await _engine.dropTable(tableName, databaseName: databaseName);
  }

  /// Returns all table names
  List<String> getTableNames() {
    return _engine.getTableNames();
  }
}
