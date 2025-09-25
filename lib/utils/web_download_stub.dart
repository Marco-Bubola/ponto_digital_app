// Stub implementation for platforms without dart:html
Future<void> downloadCsv(String filename, String csv) async {
  throw UnsupportedError('Web download not supported on this platform');
}
