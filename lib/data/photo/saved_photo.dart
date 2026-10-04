import 'dart:io';

/// 앱 저장소에 복사해 둔 사진 한 장.
///
/// 인덱스 파일에는 파일 이름만 저장하고, 불러올 때 사진 폴더 기준 절대 경로로 바꾼다.
class SavedPhoto {
  const SavedPhoto({
    required this.id,
    required this.file,
    required this.addedAt,
  });

  factory SavedPhoto.fromJson(Map<String, dynamic> json, Directory dir) {
    return SavedPhoto(
      id: json['id'] as String,
      file: File('${dir.path}/${json['fileName'] as String}'),
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  final String id;
  final File file;
  final DateTime addedAt;

  String get fileName => file.uri.pathSegments.last;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'addedAt': addedAt.toIso8601String(),
  };
}
