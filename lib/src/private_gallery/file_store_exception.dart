class FileStoreException implements Exception {
  final String message;
  FileStoreException(this.message);
  @override
  String toString() => 'FileStoreException: $message';
}
