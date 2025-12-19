import 'dart:typed_data';

import 'package:flutter/foundation.dart';

@immutable
class LocalImage {
  const LocalImage({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

