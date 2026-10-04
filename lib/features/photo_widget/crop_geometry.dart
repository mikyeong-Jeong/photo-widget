import 'dart:math' as math;
import 'dart:ui';

/// 직접 맞추기 화면의 계산.
///
/// 화면에 위젯 비율의 틀([frameSize])이 있고, 그 뒤에서 사진([imageSize])을 확대·이동한다.
/// 틀 안에 보이는 부분이 위젯에 보일 영역이며, 사진 크기에 대한 비율 [Rect] (0~1)로 나타낸다.
///
/// - 확대 배율 1 은 사진이 틀을 꽉 채우는 크기(꽉 채우기와 같음)다. 그보다 작게는 줄일 수 없다.
/// - 사진이 틀 밖으로 밀려나 빈 곳이 생기지 않게 위치를 제한한다.
class CropGeometry {
  const CropGeometry({required this.imageSize, required this.frameSize});

  final Size imageSize;
  final Size frameSize;

  static const maxZoom = 8.0;

  /// 확대 배율 1 일 때 사진 1px 이 화면에서 차지하는 크기.
  double get _coverScale => math.max(
    frameSize.width / imageSize.width,
    frameSize.height / imageSize.height,
  );

  /// [zoom] 배율일 때 화면에 그려지는 사진 크기.
  Size displaySize(double zoom) => imageSize * (_coverScale * zoom);

  /// 처음 상태: 확대 없이 가운데. (꽉 채우기와 같은 영역)
  CropView initial() {
    final size = displaySize(1);
    return CropView(
      zoom: 1,
      offset: Offset(
        (frameSize.width - size.width) / 2,
        (frameSize.height - size.height) / 2,
      ),
    );
  }

  /// 저장된 영역 [crop] 을 화면 상태로. 틀 비율이 영역 비율과 다르면 영역 가운데를 기준으로 맞춘다.
  CropView fromCrop(Rect crop) {
    final zoom = math
        .max(
          frameSize.width / (imageSize.width * _coverScale * crop.width),
          frameSize.height / (imageSize.height * _coverScale * crop.height),
        )
        .clamp(1.0, maxZoom);
    final size = displaySize(zoom);
    final center = Offset(
      crop.center.dx * size.width,
      crop.center.dy * size.height,
    );
    return _clamp(
      CropView(
        zoom: zoom,
        offset: Offset(
          frameSize.width / 2 - center.dx,
          frameSize.height / 2 - center.dy,
        ),
      ),
    );
  }

  /// 화면 상태에서 틀 안에 보이는 영역.
  Rect toCrop(CropView view) {
    final size = displaySize(view.zoom);
    final left = (-view.offset.dx / size.width).clamp(0.0, 1.0);
    final top = (-view.offset.dy / size.height).clamp(0.0, 1.0);
    return Rect.fromLTRB(
      left,
      top,
      (left + frameSize.width / size.width).clamp(0.0, 1.0),
      (top + frameSize.height / size.height).clamp(0.0, 1.0),
    );
  }

  /// 두 손가락 제스처. [start] 상태에서 [focalStart] 지점에 있던 사진 위치가
  /// [focalNow] 로 오도록 옮기고, [scale] 배 확대한다. (좌표는 틀 기준)
  CropView transform(
    CropView start, {
    required Offset focalStart,
    required Offset focalNow,
    double scale = 1,
  }) {
    final zoom = (start.zoom * scale).clamp(1.0, maxZoom);
    final startScale = _coverScale * start.zoom;
    final newScale = _coverScale * zoom;
    final imagePoint = (focalStart - start.offset) / startScale;
    return _clamp(
      CropView(zoom: zoom, offset: focalNow - imagePoint * newScale),
    );
  }

  CropView _clamp(CropView view) {
    final size = displaySize(view.zoom);
    return CropView(
      zoom: view.zoom,
      offset: Offset(
        view.offset.dx.clamp(frameSize.width - size.width, 0.0),
        view.offset.dy.clamp(frameSize.height - size.height, 0.0),
      ),
    );
  }

  /// 화면에서 위젯 비율 [aspectRatio] 의 틀을 [available] 안에 가장 크게 놓은 크기.
  static Size frameFor(Size available, double aspectRatio) {
    final byWidth = Size(available.width, available.width / aspectRatio);
    if (byWidth.height <= available.height) return byWidth;
    return Size(available.height * aspectRatio, available.height);
  }
}

/// 직접 맞추기 화면의 상태: 확대 배율과 틀 왼쪽 위 기준 사진 위치.
class CropView {
  const CropView({required this.zoom, required this.offset});

  final double zoom;
  final Offset offset;
}
