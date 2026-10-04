import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_widget/data/widget/photo_widget_bridge.dart';
import 'package:photo_widget/features/photo_widget/crop_geometry.dart';

void main() {
  // 가로 2:1 사진을 정사각형 위젯 틀에 맞추는 경우.
  const geometry = CropGeometry(
    imageSize: Size(400, 200),
    frameSize: Size(100, 100),
  );

  Matcher rectCloseTo(Rect expected) => isA<Rect>()
      .having((r) => r.left, 'left', closeTo(expected.left, 1e-6))
      .having((r) => r.top, 'top', closeTo(expected.top, 1e-6))
      .having((r) => r.right, 'right', closeTo(expected.right, 1e-6))
      .having((r) => r.bottom, 'bottom', closeTo(expected.bottom, 1e-6));

  test('처음에는 꽉 채우기와 같은 가운데 영역', () {
    expect(
      geometry.toCrop(geometry.initial()),
      rectCloseTo(const Rect.fromLTRB(0.25, 0, 0.75, 1)),
    );
  });

  test('틀 가운데를 기준으로 2배 확대하면 가운데 절반 영역', () {
    final zoomed = geometry.transform(
      geometry.initial(),
      focalStart: const Offset(50, 50),
      focalNow: const Offset(50, 50),
      scale: 2,
    );
    expect(
      geometry.toCrop(zoomed),
      rectCloseTo(const Rect.fromLTRB(0.375, 0.25, 0.625, 0.75)),
    );
  });

  test('꽉 채우기보다 작게 줄이거나 8배보다 크게 키울 수 없다', () {
    final start = geometry.initial();
    final shrunk = geometry.transform(
      start,
      focalStart: const Offset(50, 50),
      focalNow: const Offset(50, 50),
      scale: 0.2,
    );
    final enlarged = geometry.transform(
      start,
      focalStart: const Offset(50, 50),
      focalNow: const Offset(50, 50),
      scale: 100,
    );
    expect(shrunk.zoom, 1);
    expect(enlarged.zoom, CropGeometry.maxZoom);
  });

  test('사진을 틀 밖으로 밀어내도 빈 곳이 생기지 않는다', () {
    final dragged = geometry.transform(
      geometry.initial(),
      focalStart: const Offset(50, 50),
      focalNow: const Offset(1000, -1000),
    );
    expect(
      geometry.toCrop(dragged),
      rectCloseTo(const Rect.fromLTRB(0, 0, 0.5, 1)),
    );
  });

  test('저장한 영역을 다시 열면 같은 영역이 보인다', () {
    const saved = Rect.fromLTRB(0.1, 0.2, 0.35, 0.7);
    expect(geometry.toCrop(geometry.fromCrop(saved)), rectCloseTo(saved));
  });

  test('위젯 비율이 바뀌면 저장한 영역의 가운데를 기준으로 맞춘다', () {
    const wide = CropGeometry(
      imageSize: Size(400, 200),
      frameSize: Size(200, 100),
    );
    const saved = Rect.fromLTRB(0.4, 0.2, 0.6, 0.6); // 정사각형 틀에서 맞춘 영역
    final crop = wide.toCrop(wide.fromCrop(saved));
    expect(crop.center.dx, closeTo(saved.center.dx, 1e-6));
    expect(crop.center.dy, closeTo(saved.center.dy, 1e-6));
    expect(crop.width * 400 / (crop.height * 200), closeTo(2, 1e-6));
  });

  test('틀은 위젯 비율을 지키며 화면 안에 가장 크게 들어간다', () {
    expect(
      CropGeometry.frameFor(const Size(300, 600), 2),
      const Size(300, 150),
    );
    expect(
      CropGeometry.frameFor(const Size(300, 200), 0.5),
      const Size(100, 200),
    );
  });

  group('영역 저장 형식', () {
    test('저장했다가 다시 읽을 수 있다', () {
      const crop = Rect.fromLTRB(0.1, 0.2, 0.35, 0.7);
      final decoded = PhotoWidgetBridge.decodeCrop(
        PhotoWidgetBridge.encodeCrop(crop),
      );
      expect(decoded, rectCloseTo(crop));
    });

    test('잘못된 값은 무시한다', () {
      expect(PhotoWidgetBridge.decodeCrop(''), isNull);
      expect(PhotoWidgetBridge.decodeCrop('0,0,1'), isNull);
      expect(PhotoWidgetBridge.decodeCrop('0,0,a,1'), isNull);
      expect(PhotoWidgetBridge.decodeCrop('0.5,0,0.2,1'), isNull);
      expect(PhotoWidgetBridge.decodeCrop('-0.1,0,1,1'), isNull);
    });
  });
}
