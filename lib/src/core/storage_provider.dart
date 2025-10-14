/// Abstract class for storage providers
abstract class StorageProvider {
  Future<String?> read(String key);
  Future<void> write(String key, String data);
  Future<bool> exists(String key);
  Future<void> delete(String key);
}
