import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<({Uint8List bytes, String filename})?> pickFeedVideoBytes(
  BuildContext context,
) async {
  final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final name = file.name.trim().isEmpty ? 'video.mp4' : file.name;
  return (bytes: bytes, filename: name);
}
