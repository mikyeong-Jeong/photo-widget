import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_widget/data/photo/photo_repository.dart';

void main() {
  late Directory root;
  late Directory gallery;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('photo_repo_root');
    gallery = await Directory.systemTemp.createTemp('photo_repo_gallery');
  });

  tearDown(() async {
    await root.delete(recursive: true);
    await gallery.delete(recursive: true);
  });

  PhotoRepository newRepository() => PhotoRepository(() async => root);

  Future<String> galleryImage(String name) async {
    final file = File('${gallery.path}/$name');
    await file.writeAsBytes([1, 2, 3]);
    return file.path;
  }

  test('처음에는 비어 있다', () async {
    expect(await newRepository().loadAll(), isEmpty);
  });

  test('추가한 사진은 앱 폴더로 복사되고 다시 열어도 남아 있다', () async {
    final source = await galleryImage('a.JPG');

    final added = await newRepository().add([source]);

    expect(added, hasLength(1));
    expect(added.single.file.path, startsWith('${root.path}/photos/'));
    expect(added.single.file.path, endsWith('.jpg'));
    expect(await added.single.file.readAsBytes(), [1, 2, 3]);

    final reloaded = await newRepository().loadAll();
    expect(reloaded.map((p) => p.id), [added.single.id]);
  });

  test('새로 추가한 사진이 목록 앞에 온다', () async {
    final repo = newRepository();
    final first = await repo.add([await galleryImage('a.jpg')]);
    final second = await repo.add([
      await galleryImage('b.png'),
      await galleryImage('c.png'),
    ]);

    expect(second, hasLength(3));
    expect(second.last.id, first.single.id);
  });

  test('원본을 지워도 복사본은 남는다', () async {
    final source = await galleryImage('a.jpg');
    await newRepository().add([source]);

    await File(source).delete();

    expect(await newRepository().loadAll(), hasLength(1));
  });

  test('지우면 목록과 파일에서 모두 빠진다', () async {
    final repo = newRepository();
    final added = await repo.add([
      await galleryImage('a.jpg'),
      await galleryImage('b.jpg'),
    ]);

    final updated = await repo.remove(added.first.id);

    expect(updated.map((p) => p.id), [added.last.id]);
    expect(await added.first.file.exists(), isFalse);
    expect(await newRepository().loadAll(), hasLength(1));
  });

  test('파일이 없어진 항목은 목록에서 뺀다', () async {
    final added = await newRepository().add([await galleryImage('a.jpg')]);
    await added.single.file.delete();

    expect(await newRepository().loadAll(), isEmpty);
  });

  test('인덱스 파일이 깨지면 남은 사진 파일로 다시 만든다', () async {
    final added = await newRepository().add([await galleryImage('a.jpg')]);
    await File('${root.path}/photos/photos.json').writeAsString('{broken');

    final reloaded = await newRepository().loadAll();

    expect(reloaded.map((p) => p.id), [added.single.id]);
  });
}
