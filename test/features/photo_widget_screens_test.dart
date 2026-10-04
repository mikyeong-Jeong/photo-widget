import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_widget/data/photo/saved_photo.dart';
import 'package:photo_widget/data/widget/photo_widget_bridge.dart';
import 'package:photo_widget/features/photo_widget/photo_widget_app.dart';

import '../fakes.dart';

const _widgetId = 7;

/// 사진 보기 화면은 실제 파일이 있는지 확인하므로, 그 비동기 작업이 끝날 때까지 기다린다.
Future<void> _settleWithFileIo(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  group('위젯을 놓을 때 (사진 고르기)', () {
    WidgetLaunch configure() => const WidgetLaunch(
      widgetId: _widgetId,
      mode: WidgetLaunchMode.configure,
    );

    testWidgets('사진을 누르면 그 위젯에 걸고 설정을 끝낸다', (tester) async {
      final photos = [fakePhoto('a'), fakePhoto('b')];
      final bridge = FakePhotoWidgetBridge(launchInfo: configure());
      await tester.pumpWidget(
        testApp(
          repository: FakePhotoRepository(photos),
          bridge: bridge,
          child: const WidgetScreensApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Image).last);
      // 고른 뒤에는 Activity 가 닫힐 때까지 로딩 표시가 계속 돈다.
      await tester.pump();

      expect(bridge.paths, {_widgetId: photos.last.file.path});
      expect(bridge.finished, isTrue);
    });

    testWidgets('지금 걸려 있는 사진에 선택 표시를 한다', (tester) async {
      final photos = [fakePhoto('a'), fakePhoto('b')];
      await tester.pumpWidget(
        testApp(
          repository: FakePhotoRepository(photos),
          bridge: FakePhotoWidgetBridge(
            launchInfo: configure(),
            paths: {_widgetId: photos.first.file.path},
          ),
          child: const WidgetScreensApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('저장한 사진이 없으면 새로 한 장 골라 바로 건다', (tester) async {
      final bridge = FakePhotoWidgetBridge(launchInfo: configure());
      await tester.pumpWidget(
        testApp(
          repository: FakePhotoRepository(),
          bridge: bridge,
          picked: ['new'],
          child: const WidgetScreensApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('저장한 사진이 없어요'), findsOneWidget);

      await tester.tap(find.text('사진 추가'));
      await tester.pump();

      expect(bridge.paths[_widgetId], fakePhoto('new').file.path);
      expect(bridge.finished, isTrue);
    });
  });

  group('위젯을 눌렀을 때 (원본 사진 보기)', () {
    late Directory dir;
    late SavedPhoto shown;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('viewer_test');
      final file = File('${dir.path}/shown.jpg');
      await file.writeAsBytes([0]);
      shown = SavedPhoto(id: 'shown', file: file, addedAt: DateTime(2026));
    });

    tearDown(() => dir.delete(recursive: true));

    WidgetLaunch view() =>
        const WidgetLaunch(widgetId: _widgetId, mode: WidgetLaunchMode.view);

    testWidgets('사진 고르기가 아니라 걸린 사진을 보여준다', (tester) async {
      await tester.pumpWidget(
        testApp(
          repository: FakePhotoRepository([shown, fakePhoto('other')]),
          bridge: FakePhotoWidgetBridge(
            launchInfo: view(),
            paths: {_widgetId: shown.file.path},
          ),
          child: const WidgetScreensApp(),
        ),
      );
      await _settleWithFileIo(tester);

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('위젯에 걸 사진 고르기'), findsNothing);
      expect(find.text('사진 바꾸기'), findsOneWidget);
    });

    testWidgets('보기 방식을 바꾸면 저장하고 위젯을 다시 그린다', (tester) async {
      final bridge = FakePhotoWidgetBridge(
        launchInfo: view(),
        paths: {_widgetId: shown.file.path},
      );
      await tester.pumpWidget(
        testApp(
          repository: FakePhotoRepository([shown]),
          bridge: bridge,
          child: const WidgetScreensApp(),
        ),
      );
      await _settleWithFileIo(tester);

      await tester.tap(find.text('꽉 채우기'));
      await tester.pumpAndSettle();

      expect(bridge.fits[_widgetId], PhotoFit.fill);
      expect(bridge.refreshCount, 1);
    });

    testWidgets('사진 바꾸기로 다른 사진을 고르면 보기 화면으로 돌아온다', (tester) async {
      final other = fakePhoto('other');
      final bridge = FakePhotoWidgetBridge(
        launchInfo: view(),
        paths: {_widgetId: shown.file.path},
      );
      await tester.pumpWidget(
        testApp(
          repository: FakePhotoRepository([shown, other]),
          bridge: bridge,
          child: const WidgetScreensApp(),
        ),
      );
      await _settleWithFileIo(tester);

      await tester.tap(find.text('사진 바꾸기'));
      await tester.pumpAndSettle();
      expect(find.text('위젯에 걸 사진 고르기'), findsOneWidget);

      await tester.tap(find.byType(Image).last);
      await tester.pumpAndSettle();

      expect(bridge.paths[_widgetId], other.file.path);
      expect(bridge.finished, isFalse);
      expect(find.text('위젯 사진을 바꿨어요'), findsOneWidget);
      expect(find.text('사진 바꾸기'), findsOneWidget);
    });

    testWidgets('닫기를 누르면 위젯 화면을 닫는다', (tester) async {
      final bridge = FakePhotoWidgetBridge(
        launchInfo: view(),
        paths: {_widgetId: shown.file.path},
      );
      await tester.pumpWidget(
        testApp(
          repository: FakePhotoRepository([shown]),
          bridge: bridge,
          child: const WidgetScreensApp(),
        ),
      );
      await _settleWithFileIo(tester);

      await tester.tap(find.byType(CloseButton));
      await tester.pump();

      expect(bridge.closed, isTrue);
    });
  });
}
