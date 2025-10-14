import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'storage_provider.dart';

/// File-based storage provider
/// Stores data in the app's internal directory
class FileStorageProvider implements StorageProvider {
  String? _basePath;

  /// Initializes the provider
  Future<void> initialize() async {
    if (kIsWeb) {
      // Web has no file access
      throw UnsupportedError('FileStorageProvider not supported on Web');
    }

    final Directory directory = await getApplicationSupportDirectory();
    _basePath = directory.path;
  }

  String _getFilePath(String key) {
    if (_basePath == null) {
      throw StateError('StorageProvider not initialized');
    }
    return '$_basePath/$key.json';
  }

  @override
  Future<String?> read(String key) async {
    try {
      final File file = File(_getFilePath(key));
      debugPrint('🔍 Reading from: ${file.path}');
      debugPrint('📁 File exists: ${file.existsSync()}');
      if (file.existsSync()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('Error reading: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, String data) async {
    try {
      final File file = File(_getFilePath(key));
      debugPrint('💾 Writing to: ${file.path}');
      await file.writeAsString(data);
      debugPrint('✅ Write successful');
    } catch (e) {
      debugPrint('Error writing: $e');
      rethrow;
    }
  }

  @override
  Future<bool> exists(String key) async {
    try {
      final File file = File(_getFilePath(key));
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final File file = File(_getFilePath(key));
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }
}
