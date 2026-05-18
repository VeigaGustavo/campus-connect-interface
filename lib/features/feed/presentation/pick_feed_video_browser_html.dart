import 'dart:async';
import 'dart:typed_data';

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Uint8List? _bytesFromFileReaderResult(Object? result) {
  if (result == null) return null;
  if (result is Uint8List) return Uint8List.fromList(result);
  if (result is ByteBuffer) return Uint8List.view(result);
  try {
    return Uint8List.fromList((result as List<dynamic>).cast<int>());
  } catch (_) {
    return null;
  }
}

Future<({Uint8List bytes, String filename})?> pickFeedVideoBytes(
  dynamic context,
) async {
  final input = html.FileUploadInputElement()..accept = 'video/*';
  final completer = Completer<({Uint8List bytes, String filename})?>();
  Timer? cancelTimer;

  void finish(({Uint8List bytes, String filename})? value) {
    cancelTimer?.cancel();
    if (!completer.isCompleted) completer.complete(value);
    input.remove();
  }

  input.onChange.listen((_) {
    cancelTimer?.cancel();
    final files = input.files;
    if (files == null || files.isEmpty) {
      finish(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      final bytes = _bytesFromFileReaderResult(reader.result);
      if (bytes == null || bytes.isEmpty) {
        finish(null);
        return;
      }
      final name = file.name.trim().isEmpty ? 'video.mp4' : file.name;
      finish((bytes: bytes, filename: name));
    });
    reader.onError.listen((_) => finish(null));
    reader.readAsArrayBuffer(file);
  });

  html.document.body?.append(input);
  input.style.display = 'none';
  input.click();

  cancelTimer = Timer(const Duration(seconds: 90), () => finish(null));
  return completer.future;
}
