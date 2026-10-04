import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// 사진을 고르는 곳.
enum PhotoSource {
  /// 폰의 갤러리 앱(삼성 갤러리 등). 갤러리 앱의 앨범별로 고를 수 있다.
  galleryApp,

  /// Android 시스템 사진 선택기. 최근 사진 순으로 보여준다.
  recent,
}

/// 갤러리에서 사진 여러 장을 고른다.
///
/// 어느 쪽에서 골라도 긴 변 [maxDimension] px 이하로 줄인 임시 파일 경로를 돌려준다.
/// 저장소 권한은 필요 없다.
class GalleryPicker {
  GalleryPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _galleryAppChannel = MethodChannel('photo_widget/gallery');

  /// 위젯은 큰 화면에서도 이 정도면 충분하고, 원본을 그대로 쓰면 위젯 메모리 한도를 넘기 쉽다.
  /// Android `GalleryAppPicker.MAX_SIDE` 와 같게.
  static const maxDimension = 1600.0;

  /// 고른 사진(크기를 줄인 임시 파일)의 경로. 취소하면 빈 목록.
  ///
  /// 사진을 고를 수 있는 갤러리 앱이 없으면 `PlatformException(code: 'no_gallery')`.
  Future<List<String>> pickImages(PhotoSource source) => switch (source) {
    PhotoSource.galleryApp => _pickFromGalleryApp(),
    PhotoSource.recent => _pickRecent(),
  };

  Future<List<String>> _pickFromGalleryApp() async {
    final paths = await _galleryAppChannel.invokeListMethod<String>(
      'pickFromGalleryApp',
    );
    return paths ?? const [];
  }

  Future<List<String>> _pickRecent() async {
    final files = await _picker.pickMultiImage(
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    return [for (final file in files) file.path];
  }
}
