import 'file_exporter_stub.dart'
    if (dart.library.io) 'file_exporter_io.dart'
    if (dart.library.html) 'file_exporter_web.dart';

abstract final class FileExporter {
  static Future<String> saveBytes({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) =>
      saveExportedBytes(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );
}

