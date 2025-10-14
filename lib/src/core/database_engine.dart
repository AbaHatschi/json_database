import 'package:flutter/foundation.dart';

import '../core/file_storage_provider.dart';
import '../core/json_serializer.dart';
import '../core/storage_provider.dart';

/// Main engine of the database
/// Singleton pattern - only one instance for the entire app
class DatabaseEngine {
  DatabaseEngine._();
  static DatabaseEngine? _instance;
  static DatabaseEngine get instance => _instance ??= DatabaseEngine._();

  // Private Members
  StorageProvider? _storageProvider;
  final Map<String, List<Map<String, dynamic>>> _tables =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, int> _autoIncrementCounters = <String, int>{};
  bool _isInitialized = false;

  /// Initializes the database
  Future<void> initialize({
    String databaseName = 'database',
    StorageProvider? customProvider,
  }) async {
    if (_isInitialized) {
      debugPrint('Database already initialized');
      return;
    }

    // Storage Provider setup
    _storageProvider = customProvider ?? FileStorageProvider();
    if (_storageProvider is FileStorageProvider) {
      await (_storageProvider! as FileStorageProvider).initialize();
    }

    // Load existing data
    await _loadDatabase(databaseName);
    _isInitialized = true;

    debugPrint('Database initialized: $databaseName');
  }

  /// Loads the database from storage
  Future<void> _loadDatabase(String databaseName) async {
    debugPrint('🔍 Trying to load database: $databaseName');
    try {
      final String? jsonString = await _storageProvider!.read(databaseName);
      debugPrint('📄 JSON data found: ${jsonString != null ? 'YES' : 'NO'}');
      if (jsonString != null) {
        final Map<String, dynamic> data = JsonSerializer.decodeToMap(
          jsonString,
        );

        // Load tables
        if (data['tables'] != null) {
          _tables.clear();
          final Map<String, dynamic> tablesData =
              data['tables'] as Map<String, dynamic>;
          for (final MapEntry<String, dynamic> entry in tablesData.entries) {
            final List<dynamic> rawList = entry.value as List<dynamic>;
            _tables[entry.key] = rawList
                .map((dynamic item) => item as Map<String, dynamic>)
                .toList();
          }
        }

        // Auto-Increment Counters laden
        if (data['autoIncrementCounters'] != null) {
          _autoIncrementCounters.clear();
          final Map<String, dynamic> countersData =
              data['autoIncrementCounters'] as Map<String, dynamic>;
          for (final MapEntry<String, dynamic> entry in countersData.entries) {
            _autoIncrementCounters[entry.key] = entry.value as int;
          }
        }

        debugPrint('Database loaded: ${_tables.keys.length} tables');
      }
    } catch (e) {
      debugPrint('Error loading database: $e');
      // Start with empty database on error
      _tables.clear();
      _autoIncrementCounters.clear();
    }
  }

  /// Saves the database
  Future<void> _saveDatabase(String databaseName) async {
    try {
      final Map<String, Object> data = <String, Object>{
        'tables': _tables,
        'autoIncrementCounters': _autoIncrementCounters,
        'lastModified': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      final String jsonString = JsonSerializer.encode(data);
      await _storageProvider!.write(databaseName, jsonString);
    } catch (e) {
      debugPrint('Error saving database: $e');
      rethrow;
    }
  }

  /// Checks if the database is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
  }

  /// Creates a new table
  void createTable(String tableName) {
    _ensureInitialized();
    if (!_tables.containsKey(tableName)) {
      _tables[tableName] = <Map<String, dynamic>>[];
      _autoIncrementCounters[tableName] = 0;
      //! Table created: $tableName
    }
  }

  /// Checks if a table exists
  bool tableExists(String tableName) {
    _ensureInitialized();
    return _tables.containsKey(tableName);
  }

  /// Returns all table names
  List<String> getTableNames() {
    _ensureInitialized();
    return _tables.keys.toList();
  }

  /// Returns all records of a table
  List<Map<String, dynamic>> getTableData(String tableName) {
    _ensureInitialized();
    createTable(tableName); // Create if not exists
    return List<Map<String, dynamic>>.from(_tables[tableName]!);
  }

  /// Generates the next ID for a table
  int _getNextId(String tableName) {
    _autoIncrementCounters[tableName] =
        (_autoIncrementCounters[tableName] ?? 0) + 1;
    return _autoIncrementCounters[tableName]!;
  }

  /// Adds a record
  Future<Map<String, dynamic>> insert(
    String tableName,
    Map<String, dynamic> data, {
    String databaseName = 'database',
  }) async {
    _ensureInitialized();
    createTable(tableName);

    // Assign new ID if not present
    if (data['id'] == null) {
      data = Map<String, dynamic>.from(data);
      data['id'] = _getNextId(tableName);
    }

    _tables[tableName]!.add(data);
    await _saveDatabase(databaseName);

    return data;
  }

  /// Searches records
  List<Map<String, dynamic>> find(
    String tableName, {
    Map<String, dynamic>? where,
  }) {
    _ensureInitialized();
    createTable(tableName);

    final List<Map<String, dynamic>> tableData = _tables[tableName]!;

    if (where == null || where.isEmpty) {
      return List<Map<String, dynamic>>.from(tableData);
    }

    return tableData.where((Map<String, dynamic> row) {
      for (final MapEntry<String, dynamic> entry in where.entries) {
        if (row[entry.key] != entry.value) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Searches a record by ID
  Map<String, dynamic>? findById(String tableName, int id) {
    final List<Map<String, dynamic>> results = find(
      tableName,
      where: <String, dynamic>{'id': id},
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Updates records
  Future<int> update(
    String tableName,
    Map<String, dynamic> data, {
    required Map<String, dynamic> where,
    String databaseName = 'database',
  }) async {
    _ensureInitialized();
    createTable(tableName);

    final List<Map<String, dynamic>> tableData = _tables[tableName]!;
    int updatedCount = 0;

    for (int i = 0; i < tableData.length; i++) {
      final Map<String, dynamic> row = tableData[i];
      bool matches = true;

      for (final MapEntry<String, dynamic> entry in where.entries) {
        if (row[entry.key] != entry.value) {
          matches = false;
          break;
        }
      }

      if (matches) {
        // Merge new data (without overwriting ID)
        final Map<String, dynamic> updatedRow = Map<String, dynamic>.from(row);
        for (final MapEntry<String, dynamic> entry in data.entries) {
          if (entry.key != 'id') {
            // Do not overwrite ID
            updatedRow[entry.key] = entry.value;
          }
        }
        tableData[i] = updatedRow;
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      await _saveDatabase(databaseName);
    }

    return updatedCount;
  }

  /// Deletes records
  Future<int> delete(
    String tableName, {
    required Map<String, dynamic> where,
    String databaseName = 'database',
  }) async {
    _ensureInitialized();
    createTable(tableName);

    final List<Map<String, dynamic>> tableData = _tables[tableName]!;
    final int originalLength = tableData.length;

    _tables[tableName] = tableData.where((Map<String, dynamic> row) {
      for (final MapEntry<String, dynamic> entry in where.entries) {
        if (row[entry.key] != entry.value) {
          return true; // Keep
        }
      }
      return false; // Delete
    }).toList();

    final int deletedCount = originalLength - _tables[tableName]!.length;

    if (deletedCount > 0) {
      await _saveDatabase(databaseName);
    }

    return deletedCount;
  }

  /// Deletes a complete table
  Future<void> dropTable(
    String tableName, {
    String databaseName = 'database',
  }) async {
    _ensureInitialized();
    _tables.remove(tableName);
    _autoIncrementCounters.remove(tableName);
    await _saveDatabase(databaseName);
    debugPrint('Table deleted: $tableName');
  }

  /// Closes the database (cleanup)
  Future<void> close({String databaseName = 'database'}) async {
    if (_isInitialized) {
      await _saveDatabase(databaseName);
      _tables.clear();
      _autoIncrementCounters.clear();
      _isInitialized = false;
      debugPrint('Database closed');
    }
  }
}
