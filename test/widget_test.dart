import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_widget/app/app.dart';
import 'package:photo_widget/data/photo/gallery_picker.dart';
import 'package:photo_widget/data/photo/photo_repository.dart';
import 'package:photo_widget/data/photo/saved_photo.dart';
import 'package:photo_widget/features/photos/photo_list_controller.dart';

/// 파일 시스템 없이 동작하는 저장소.
class FakePhotoRepository implements PhotoRepository {
  FakePhotoRepository([List<SavedPhoto>? photos]) : photos = photos ?? [];

  List<SavedPhoto> photos;

  @override
  Future<List<SavedPhoto>> loadAll() async => photos;

  @override
  Future<List<SavedPhoto>> add(List<String> sourcePaths) async {
    return photos = [for (final path in sourcePaths) _photo(path), ...photos];
  }

  @override
  Future<List<SavedPhoto>> remove(String id) async {
    return photos = [
      for (final p in photos)
        if (p.id != id) p,
    ];
  }
}

class FakeGalleryPicker implements GalleryPicker {
  FakeGalleryPicker(this.result);

  final List<String> result;

  @override
  Future<List<String>> pickImages() async => result;
}

SavedPhoto _photo(String id) => SavedPhoto(
  id: id,
  file: File('/nonexistent/$id.jpg'),
  addedAt: DateTime(2026),
);

Widget _app({
  required PhotoRepository repository,
  List<String> picked = const [],
}) {
  return ProviderScope(
    overrides: [
      photoRepositoryProvider.overrideWithValue(repository),
      galleryPickerProvider.overrideWithValue(FakeGalleryPicker(picked)),
    ],
    child: const PhotoWidgetApp(),
  );
}

void main() {
  testWidgets('사진이 없으면 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(_app(repository: FakePhotoRepository()));
    await tester.pumpAndSettle();

    expect(find.text('사진 위젯'), findsOneWidget);
    expect(find.text('아직 위젯에 걸어둔 사진이 없어요'), findsOneWidget);
  });

  testWidgets('저장된 사진을 그리드로 보여준다', (tester) async {
    await tester.pumpWidget(
      _app(repository: FakePhotoRepository([_photo('a'), _photo('b')])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('사진 추가 버튼으로 고른 사진이 목록에 들어간다', (tester) async {
    final repository = FakePhotoRepository();
    await tester.pumpWidget(_app(repository: repository, picked: ['x', 'y']));
    await tester.pumpAndSettle();

    await tester.tap(find.text('사진 추가'));
    await tester.pumpAndSettle();

    expect(repository.photos, hasLength(2));
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.text('사진 2장을 추가했어요'), findsOneWidget);
  });

  testWidgets('길게 눌러 지울 수 있다', (tester) async {
    final repository = FakePhotoRepository([_photo('a')]);
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(Image));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();

    expect(repository.photos, isEmpty);
    expect(find.text('아직 위젯에 걸어둔 사진이 없어요'), findsOneWidget);
  });
}
