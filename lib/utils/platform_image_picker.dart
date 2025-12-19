import 'package:cocoshibaweb/models/local_image.dart';

import 'platform_image_picker_stub.dart'
    if (dart.library.html) 'platform_image_picker_web.dart';

abstract class PlatformImagePicker {
  Future<List<LocalImage>> pickMultiImage();
}

PlatformImagePicker createPlatformImagePicker() => createImagePicker();

