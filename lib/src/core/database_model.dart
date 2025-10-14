/// Basic interface for all database models
///
/// Every model that is to be stored in the database,
/// must implement this interface.
abstract class DatabaseModel {
  /// Unique ID of the record
  /// null = not yet saved, will be automatically assigned
  int? get id;

  /// Sets the ID of the record (used by the DB)
  set id(int? value);

  /// Converts the model to JSON for storage
  Map<String, dynamic> toJson();
}
