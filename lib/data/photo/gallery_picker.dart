import 'package:image_picker/image_picker.dart';

/// 갤러리에서 사진 여러 장을 고른다.
///
/// Android 13 이상은 시스템 사진 선택기를 쓰므로 저장소 권한이 필요 없다.
class GalleryPicker {
  GalleryPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// 위젯은 큰 화면에서도 이 정도면 충분하고, 원본을 그대로 쓰면 위젯 메모리 한도를 넘기 쉽다.
  static const maxDimension = 1600.0;

  /// 고른 사진(크기를 줄인 임시 파일)의 경로. 취소하면 빈 목록.
  Future<List<String>> pickImages() async {
    final files = await _picker.pickMultiImage(
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    return [for (final file in files) file.path];
  }
}
