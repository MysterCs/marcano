import 'dart:io';

Future<String> saveExportedBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  Directory targetDir = Directory.current;
  if (home != null && home.isNotEmpty) {
    final downloads = Directory('$home/Downloads');
    if (downloads.existsSync()) {
      targetDir = downloads;
    } else {
      targetDir = Directory(home);
    }
  }
  final file = File('${targetDir.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

