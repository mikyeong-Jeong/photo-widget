import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_widget/app/app.dart';
import 'package:photo_widget/data/photo/gallery_picker.dart';

import '../fakes.dart';

void main() {
  testWidgets('사진이 없으면 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(
      testApp(repository: FakePhotoRepository(), child: const PhotoWidgetApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('사진 위젯'), findsOneWidget);
    expect(find.text('아직 위젯에 걸어둔 사진이 없어요'), findsOneWidget);
  });

  testWidgets('저장된 사진을 그리드로 보여준다', (tester) async {
    await tester.pumpWidget(
      testApp(
        repository: FakePhotoRepository([fakePhoto('a'), fakePhoto('b')]),
        child: const PhotoWidgetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(2));
  });

  for (final (label, source) in [
    ('갤러리 앱에서 고르기', PhotoSource.galleryApp),
    ('최근 사진에서 고르기', PhotoSource.recent),
  ]) {
    testWidgets('사진 추가 → "$label" 로 고른 사진이 목록에 들어간다', (tester) async {
      final repository = FakePhotoRepository();
      final picker = FakeGalleryPicker(['x', 'y']);
      await tester.pumpWidget(
        testApp(
          repository: repository,
          picker: picker,
          child: const PhotoWidgetApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('사진 추가'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(picker.lastSource, source);
      expect(repository.photos, hasLength(2));
      expect(find.byType(Image), findsNWidgets(2));
      expect(find.text('사진 2장을 추가했어요'), findsOneWidget);
    });
  }

  testWidgets('갤러리 앱이 없으면 최근 사진에서 고르라고 안내한다', (tester) async {
    await tester.pumpWidget(
      testApp(
        repository: FakePhotoRepository(),
        picker: FakeGalleryPicker(
          [],
          error: PlatformException(code: 'no_gallery'),
        ),
        child: const PhotoWidgetApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('사진 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('갤러리 앱에서 고르기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('갤러리 앱을 찾지 못했어요'), findsOneWidget);
  });

  testWidgets('어디서 고를지 묻는 창을 닫으면 아무것도 하지 않는다', (tester) async {
    final picker = FakeGalleryPicker(['x']);
    await tester.pumpWidget(
      testApp(
        repository: FakePhotoRepository(),
        picker: picker,
        child: const PhotoWidgetApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('사진 추가'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(picker.lastSource, isNull);
    expect(find.text('아직 위젯에 걸어둔 사진이 없어요'), findsOneWidget);
  });

  testWidgets('길게 눌러 지우면 위젯도 다시 그린다', (tester) async {
    final repository = FakePhotoRepository([fakePhoto('a')]);
    final bridge = FakePhotoWidgetBridge();
    await tester.pumpWidget(
      testApp(
        repository: repository,
        bridge: bridge,
        child: const PhotoWidgetApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(Image));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();

    expect(repository.photos, isEmpty);
    expect(bridge.refreshCount, 1);
    expect(find.text('아직 위젯에 걸어둔 사진이 없어요'), findsOneWidget);
  });

  testWidgets('위젯에 걸린 사진을 지울 때는 위젯 개수를 알려준다', (tester) async {
    final photo = fakePhoto('a');
    await tester.pumpWidget(
      testApp(
        repository: FakePhotoRepository([photo]),
        bridge: FakePhotoWidgetBridge(
          paths: {1: photo.file.path, 2: photo.file.path},
        ),
        child: const PhotoWidgetApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(Image));
    await tester.pumpAndSettle();

    expect(find.textContaining('홈 화면 위젯 2개'), findsOneWidget);
  });
}
