import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_widget/features/widget_configure/widget_configure_app.dart';

import '../fakes.dart';

void main() {
  testWidgets('사진을 누르면 그 위젯에 걸고 설정을 끝낸다', (tester) async {
    final photos = [fakePhoto('a'), fakePhoto('b')];
    final bridge = FakePhotoWidgetBridge(widgetId: 7);
    await tester.pumpWidget(
      testApp(
        repository: FakePhotoRepository(photos),
        bridge: bridge,
        child: const WidgetConfigureApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Image).last);
    // 고른 뒤에는 Activity 가 닫힐 때까지 로딩 표시가 계속 돈다.
    await tester.pump();

    expect(bridge.paths, {7: photos.last.file.path});
    expect(bridge.finished, isTrue);
  });

  testWidgets('지금 걸려 있는 사진에 선택 표시를 한다', (tester) async {
    final photos = [fakePhoto('a'), fakePhoto('b')];
    await tester.pumpWidget(
      testApp(
        repository: FakePhotoRepository(photos),
        bridge: FakePhotoWidgetBridge(
          widgetId: 7,
          paths: {7: photos.first.file.path},
        ),
        child: const WidgetConfigureApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('저장한 사진이 없으면 새로 한 장 골라 바로 건다', (tester) async {
    final bridge = FakePhotoWidgetBridge(widgetId: 7);
    await tester.pumpWidget(
      testApp(
        repository: FakePhotoRepository(),
        bridge: bridge,
        picked: ['new'],
        child: const WidgetConfigureApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('저장한 사진이 없어요'), findsOneWidget);

    await tester.tap(find.text('사진 추가'));
    await tester.pump();

    expect(bridge.paths[7], fakePhoto('new').file.path);
    expect(bridge.finished, isTrue);
  });
}
