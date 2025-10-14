import 'dart:convert';

/// Utility class for JSON serialization
class JsonSerializer {
  /// Converts data to JSON string
  static String encode(dynamic data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      throw FormatException('Error encoding JSON: $e');
    }
  }

  /// Converts JSON string to data
  static dynamic decode(String jsonString) {
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      throw FormatException('Error decoding JSON: $e');
    }
  }

  /// Converts JSON string to Map
  static Map<String, dynamic> decodeToMap(String jsonString) {
    final dynamic decoded = decode(jsonString);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('JSON is not a Map');
  }

  /// Converts JSON string to List
  static List<dynamic> decodeToList(String jsonString) {
    final dynamic decoded = decode(jsonString);
    if (decoded is List) {
      return decoded;
    }
    throw const FormatException('JSON is not a List');
  }
}
