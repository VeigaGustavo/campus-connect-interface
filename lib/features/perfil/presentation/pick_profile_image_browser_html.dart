import 'dart:async';
import 'dart:convert';
// Seletor de ficheiros só para compilação web (`dart.library.html`).
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Uint8List? _bytesFromFileReaderResult(Object? result) {
  if (result == null) return null;
  if (result is Uint8List) {
    return Uint8List.fromList(result);
  }
  if (result is ByteBuffer) {
    return Uint8List.view(result);
  }
  try {
    final raw = result as List<dynamic>;
    return Uint8List.fromList(raw.cast<int>());
  } catch (_) {
    return null;
  }
}

Future<({Uint8List bytes, String filename})?> pickProfileImageInBrowser() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';

  final completer = Completer<({Uint8List bytes, String filename})?>();
  Timer? cancelGuessTimer;
  Timer? hangGuard;

  void finish(({Uint8List bytes, String filename})? value) {
    cancelGuessTimer?.cancel();
    hangGuard?.cancel();
    if (!completer.isCompleted) {
      completer.complete(value);
    }
    input.remove();
  }

  void armCancelAfterPickerCloses() {
    cancelGuessTimer?.cancel();
    cancelGuessTimer = Timer(const Duration(milliseconds: 900), () {
      if (completer.isCompleted) return;
      final f = input.files;
      if (f == null || f.isEmpty) {
        finish(null);
      }
    });
  }

  late void Function(html.Event) onWindowFocus;
  onWindowFocus = (_) {
    html.window.removeEventListener('focus', onWindowFocus);
    armCancelAfterPickerCloses();
  };

  html.window.addEventListener('focus', onWindowFocus);

  hangGuard = Timer(const Duration(minutes: 2), () {
    if (!completer.isCompleted) {
      finish(null);
    }
  });

  input.onChange.listen((_) {
    cancelGuessTimer?.cancel();
    final files = input.files;
    if (files == null || files.isEmpty) {
      html.window.removeEventListener('focus', onWindowFocus);
      finish(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      html.window.removeEventListener('focus', onWindowFocus);
      final bytes = _bytesFromFileReaderResult(reader.result);
      if (bytes == null || bytes.isEmpty) {
        finish(null);
        return;
      }
      final name = file.name.trim().isEmpty ? 'image.jpg' : file.name;
      finish((bytes: bytes, filename: name));
    });
    reader.onError.listen((_) {
      html.window.removeEventListener('focus', onWindowFocus);
      finish(null);
    });
    reader.readAsArrayBuffer(file);
  });

  html.document.body?.append(input);
  input.style.display = 'none';
  input.click();

  return completer.future;
}

Future<Uint8List> shrinkProfileImageBytesForWeb(
  Uint8List raw, {
  int maxSide = 1680,
  double jpegQuality = 0.86,
}) async {
  if (raw.isEmpty) return raw;
  final blob = html.Blob([raw]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final completer = Completer<Uint8List>();
  final img = html.ImageElement();
  StreamSubscription<html.Event>? subErr;

  void completeRaw() {
    if (!completer.isCompleted) completer.complete(raw);
  }

  subErr = img.onError.listen((_) {
    subErr?.cancel();
    html.Url.revokeObjectUrl(url);
    completeRaw();
  });

  img.onLoad.listen((_) {
    subErr?.cancel();
    try {
      final w = img.naturalWidth;
      final h = img.naturalHeight;
      if (w <= 0 || h <= 0) {
        completeRaw();
        return;
      }
      var tw = w;
      var th = h;
      if (w > maxSide || h > maxSide) {
        if (w >= h) {
          tw = maxSide;
          th = (h * maxSide / w).round();
        } else {
          th = maxSide;
          tw = (w * maxSide / h).round();
        }
      }
      final canvas = html.CanvasElement(width: tw, height: th);
      final ctx = canvas.context2D;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.scale(tw / w, th / h);
      ctx.drawImage(img, 0, 0);
      final dataUrl = canvas.toDataUrl('image/jpeg', jpegQuality);
      final i = dataUrl.indexOf(',');
      if (i < 0 || i >= dataUrl.length - 1) {
        completeRaw();
        return;
      }
      final out = base64Decode(dataUrl.substring(i + 1));
      if (!completer.isCompleted) completer.complete(out);
    } catch (_) {
      completeRaw();
    } finally {
      html.Url.revokeObjectUrl(url);
    }
  });

  img.src = url;
  return completer.future.timeout(
    const Duration(seconds: 25),
    onTimeout: () {
      subErr?.cancel();
      html.Url.revokeObjectUrl(url);
      return raw;
    },
  );
}
