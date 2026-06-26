import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> downloadFile(
    List<int> bytes, String filename, String mimeType) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return null;
}
