import 'dart:convert';
import 'dart:io';

import 'saved_photo.dart';

/// 위젯에 걸 사진을 앱 전용 폴더에 복사해 두고 목록을 관리한다.
///
/// 갤러리 원본은 사용자가 지우거나 권한이 바뀌면 읽을 수 없게 되므로,
/// 위젯은 항상 이 폴더의 복사본만 읽는다.
class PhotoRepository {
  PhotoRepository(this._rootDir);

  final Future<Directory> Function() _rootDir;
  Directory? _dir;

  static const _indexName = 'photos.json';

  Future<Directory> _photosDir() async {
    if (_dir case final dir?) return dir;
    final root = await _rootDir();
    final dir = Directory('${root.path}/photos');
    await dir.create(recursive: true);
    return _dir = dir;
  }

  /// 최근에 추가한 사진이 앞에 오는 목록. 파일이 없어진 항목은 뺀다.
  Future<List<SavedPhoto>> loadAll() async {
    final dir = await _photosDir();
    final index = File('${dir.path}/$_indexName');
    if (!await index.exists()) return [];

    List<SavedPhoto> photos;
    try {
      final json = jsonDecode(await index.readAsString()) as List<dynamic>;
      photos = [
        for (final item in json)
          SavedPhoto.fromJson(item as Map<String, dynamic>, dir),
      ];
    } on FormatException {
      photos = await _rebuildFromFiles(dir);
    }
    return [
      for (final photo in photos)
        if (await photo.file.exists()) photo,
    ];
  }

  /// [sourcePaths] 의 이미지를 사진 폴더로 복사해 목록 앞에 추가한다.
  Future<List<SavedPhoto>> add(List<String> sourcePaths) async {
    final dir = await _photosDir();
    final current = await loadAll();
    final now = DateTime.now();

    final added = <SavedPhoto>[];
    for (final (i, source) in sourcePaths.indexed) {
      final id = '${now.microsecondsSinceEpoch}_$i';
      final target = File('${dir.path}/$id${_extensionOf(source)}');
      await File(source).copy(target.path);
      added.add(SavedPhoto(id: id, file: target, addedAt: now));
    }

    final updated = [...added, ...current];
    await _save(dir, updated);
    return updated;
  }

  Future<List<SavedPhoto>> remove(String id) async {
    final dir = await _photosDir();
    final current = await loadAll();
    final updated = [
      for (final photo in current)
        if (photo.id != id) photo,
    ];
    await _save(dir, updated);
    for (final photo in current) {
      if (photo.id == id && await photo.file.exists()) {
        await photo.file.delete();
      }
    }
    return updated;
  }

  /// 임시 파일에 쓴 뒤 이름을 바꿔서, 쓰는 도중 앱이 꺼져도 인덱스가 깨지지 않게 한다.
  Future<void> _save(Directory dir, List<SavedPhoto> photos) async {
    final tmp = File('${dir.path}/$_indexName.tmp');
    await tmp.writeAsString(jsonEncode([for (final p in photos) p.toJson()]));
    await tmp.rename('${dir.path}/$_indexName');
  }

  /// 인덱스가 깨졌을 때 폴더에 남은 사진 파일로 목록을 다시 만든다.
  Future<List<SavedPhoto>> _rebuildFromFiles(Directory dir) async {
    final files = await dir
        .list()
        .where((e) => e is File && !e.path.contains(_indexName))
        .cast<File>()
        .toList();
    final photos = [
      for (final file in files)
        SavedPhoto(
          id: file.uri.pathSegments.last.split('.').first,
          file: file,
          addedAt: await file.lastModified(),
        ),
    ]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    await _save(dir, photos);
    return photos;
  }

  static String _extensionOf(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '.jpg' : name.substring(dot).toLowerCase();
  }
}
