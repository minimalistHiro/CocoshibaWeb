import 'package:cocoshibaweb/models/local_image.dart';

import 'platform_image_picker.dart';

class _StubImagePicker implements PlatformImagePicker {
  @override
  Future<List<LocalImage>> pickMultiImage() async => const <LocalImage>[];
}

PlatformImagePicker createImagePicker() => _StubImagePicker();

