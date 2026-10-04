import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'crop_geometry.dart';

/// 직접 맞추기: 위젯 비율의 틀 안에 보일 부분을 확대·이동해서 맞춘다.
///
/// [적용] 을 누르면 틀 안에 보이는 영역(사진 크기에 대한 비율 0~1)을 돌려준다.
class WidgetCropScreen extends StatefulWidget {
  const WidgetCropScreen({
    super.key,
    required this.file,
    required this.aspectRatio,
    this.initialCrop,
  });

  final File file;

  /// 위젯의 가로/세로 비율.
  final double aspectRatio;

  /// 이전에 맞춘 영역. 없으면 꽉 채우기와 같은 가운데 영역에서 시작한다.
  final Rect? initialCrop;

  @override
  State<WidgetCropScreen> createState() => _WidgetCropScreenState();
}

class _WidgetCropScreenState extends State<WidgetCropScreen> {
  static const _framePadding = 24.0;

  late final FileImage _image = FileImage(widget.file);
  ImageStream? _imageStream;
  late final _imageListener = ImageStreamListener(
    (info, _) {
      if (!mounted) return;
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
    },
    onError: (_, _) {
      if (mounted) setState(() => _failed = true);
    },
  );
  Size? _imageSize;
  bool _failed = false;

  /// 지금 틀 안에 보이는 영역. 화면 크기가 바뀌어도 유지되도록 비율로 들고 있는다.
  Rect? _crop;

  Rect? _gestureStartCrop;
  Offset _gestureStartFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _crop = widget.initialCrop;
    _imageStream = _image.resolve(ImageConfiguration.empty)
      ..addListener(_imageListener);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = _imageSize;

    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('위젯에 보일 부분 맞추기'),
        ),
        body: _failed
            ? const Center(child: Text('사진을 열지 못했어요'))
            : imageSize == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) =>
                    _buildEditor(constraints.biggest, imageSize),
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: imageSize == null
                      ? null
                      : () => setState(() => _crop = null),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('처음으로'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: imageSize == null ? null : _apply,
                  child: const Text('적용'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(Size area, Size imageSize) {
    final frameSize = CropGeometry.frameFor(
      Size(area.width - _framePadding * 2, area.height - _framePadding * 2),
      widget.aspectRatio,
    );
    final frameOrigin = Offset(
      (area.width - frameSize.width) / 2,
      (area.height - frameSize.height) / 2,
    );
    final geometry = CropGeometry(imageSize: imageSize, frameSize: frameSize);
    final view = _viewOf(geometry);
    final displaySize = geometry.displaySize(view.zoom);
    final frameRect = frameOrigin & frameSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        _gestureStartCrop = geometry.toCrop(view);
        _gestureStartFocal = details.localFocalPoint - frameOrigin;
      },
      onScaleUpdate: (details) {
        final startCrop = _gestureStartCrop;
        if (startCrop == null) return;
        final next = geometry.transform(
          geometry.fromCrop(startCrop),
          focalStart: _gestureStartFocal,
          focalNow: details.localFocalPoint - frameOrigin,
          scale: details.scale,
        );
        setState(() => _crop = geometry.toCrop(next));
      },
      onScaleEnd: (_) => _gestureStartCrop = null,
      child: Stack(
        children: [
          Positioned(
            left: frameOrigin.dx + view.offset.dx,
            top: frameOrigin.dy + view.offset.dy,
            width: displaySize.width,
            height: displaySize.height,
            child: Image(image: _image, fit: BoxFit.fill),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _FramePainter(frameRect)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: frameRect.bottom + 8,
            child: const IgnorePointer(
              child: Text(
                '두 손가락으로 확대하고, 끌어서 위치를 맞춰요',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CropView _viewOf(CropGeometry geometry) {
    final crop = _crop;
    return crop == null ? geometry.initial() : geometry.fromCrop(crop);
  }

  void _apply() {
    final imageSize = _imageSize;
    if (imageSize == null) return;
    // 아직 손대지 않았다면 처음 상태(가운데)의 영역을 쓴다. 영역은 틀 비율에만 달려 있다.
    final geometry = CropGeometry(
      imageSize: imageSize,
      frameSize: Size(widget.aspectRatio, 1),
    );
    Navigator.pop(context, _crop ?? geometry.toCrop(geometry.initial()));
  }
}

/// 틀 바깥을 어둡게 하고 틀 테두리를 그린다.
class _FramePainter extends CustomPainter {
  _FramePainter(this.frame);

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final frameShape = RRect.fromRectAndRadius(
      frame,
      const Radius.circular(16),
    );
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(frameShape);
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    canvas.drawRRect(
      frameShape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => oldDelegate.frame != frame;
}
