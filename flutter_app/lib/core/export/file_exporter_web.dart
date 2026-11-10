// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

Future<String> saveExportedBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final base64Data = base64Encode(bytes);
  final anchor = html.AnchorElement(
    href: 'data:$mimeType;base64,$base64Data',
  )
    ..setAttribute('download', filename)
    ..click();
  anchor.remove();
  return filename;
}

