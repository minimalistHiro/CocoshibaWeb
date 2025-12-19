import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cocoshibaweb/models/local_image.dart';

import 'platform_image_picker.dart';

class _WebImagePicker implements PlatformImagePicker {
  @override
  Future<List<LocalImage>> pickMultiImage() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = true;

    input.click();
    await input.onChange.first;

    final files = input.files;
    if (files == null || files.isEmpty) return const <LocalImage>[];

    final results = <LocalImage>[];
    for (final file in files) {
      final bytes = await _readAsBytes(file);
      final contentType =
          (file.type ?? '').trim().isEmpty ? 'application/octet-stream' : file.type!;
      results.add(
        LocalImage(
          bytes: bytes,
          filename: file.name,
          contentType: contentType,
        ),
      );
    }
    return results;
  }

  Future<Uint8List> _readAsBytes(html.File file) {
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(reader.error ?? StateError('Failed to read file.'));
      }
    });
    reader.onLoadEnd.first.then((_) {
      if (completer.isCompleted) return;
      final result = reader.result;
      if (result == null) {
        completer.completeError(StateError('FileReader result is null.'));
        return;
      }

      if (result is ByteBuffer) {
        completer.complete(Uint8List.view(result));
        return;
      }
      if (result is Uint8List) {
        completer.complete(result);
        return;
      }
      if (result is List<int>) {
        completer.complete(Uint8List.fromList(result));
        return;
      }

      completer.completeError(
        StateError('Unexpected FileReader result: ${result.runtimeType}'),
      );
    });
    return completer.future;
  }
}

PlatformImagePicker createImagePicker() => _WebImagePicker();
