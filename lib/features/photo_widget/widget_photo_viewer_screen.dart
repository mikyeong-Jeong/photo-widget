import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/photo/saved_photo.dart';
import '../../data/widget/photo_widget_bridge.dart';
import '../photos/photo_list_controller.dart';
import 'widget_crop_screen.dart';
import 'widget_photo_picker_screen.dart';

/// 위젯을 눌렀을 때 뜨는 원본 사진 보기.
///
/// 손가락으로 확대·이동할 수 있고, 아래에서 위젯 보기 방식과 사진을 바꾼다.
class WidgetPhotoViewerScreen extends ConsumerStatefulWidget {
  const WidgetPhotoViewerScreen({
    super.key,
    required this.widgetId,
    this.widgetAspectRatio = 1,
  });

  final int widgetId;

  /// 위젯의 가로/세로 비율. 직접 맞추기 틀에 쓴다.
  final double widgetAspectRatio;

  @override
  ConsumerState<WidgetPhotoViewerScreen> createState() =>
      _WidgetPhotoViewerScreenState();
}

class _WidgetPhotoViewerScreenState
    extends ConsumerState<WidgetPhotoViewerScreen> {
  bool _loaded = false;
  String? _path;
  bool _exists = false;
  PhotoFit _fit = PhotoFit.fit;
  Rect? _crop;

  PhotoWidgetBridge get _bridge => ref.read(photoWidgetBridgeProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await _bridge.photoPathOf(widget.widgetId);
    final fit = await _bridge.photoFitOf(widget.widgetId);
    final crop = await _bridge.photoCropOf(widget.widgetId);
    final exists = path != null && await File(path).exists();
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _path = path;
      _exists = exists;
      _fit = fit;
      _crop = crop;
    });
  }

  Future<void> _changePhoto() async {
    final picked = await Navigator.push<SavedPhoto>(
      context,
      MaterialPageRoute(
        builder: (pickerContext) => WidgetPhotoPickerScreen(
          selectedPath: _path,
          onPicked: (photo) async {
            await _bridge.assign(widget.widgetId, photo);
            if (pickerContext.mounted) Navigator.pop(pickerContext, photo);
          },
        ),
      ),
    );
    if (picked == null || !mounted) return;
    // 새 사진이면 직접 맞춘 영역은 버리고 전체 보기로 돌아간다. (PhotoWidgetBridge.assign)
    setState(() {
      _path = picked.file.path;
      _exists = true;
      _crop = null;
      if (_fit == PhotoFit.custom) _fit = PhotoFit.fit;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('위젯 사진을 바꿨어요')));
  }

  Future<void> _changeFit(PhotoFit fit) async {
    if (fit == PhotoFit.custom) return _openCropEditor();
    setState(() => _fit = fit);
    await _bridge.setPhotoFit(widget.widgetId, fit);
  }

  /// 직접 맞추기 화면을 열고, 적용하면 그 영역으로 위젯을 채운다. 취소하면 그대로 둔다.
  Future<void> _openCropEditor() async {
    final path = _path;
    if (path == null || !_exists) return;
    final crop = await Navigator.push<Rect>(
      context,
      MaterialPageRoute(
        builder: (_) => WidgetCropScreen(
          file: File(path),
          aspectRatio: widget.widgetAspectRatio,
          initialCrop: _crop,
        ),
      ),
    );
    if (crop == null || !mounted) return;
    setState(() {
      _fit = PhotoFit.custom;
      _crop = crop;
    });
    await _bridge.setCustomCrop(widget.widgetId, crop);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('맞춘 모습으로 위젯에 적용했어요')));
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;

    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black38,
          leading: CloseButton(onPressed: _bridge.close),
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : path != null && _exists
            ? InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Image.file(
                    File(path),
                    key: ValueKey(path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined, size: 56),
                  ),
                ),
              )
            : _MissingPhoto(onPick: _changePhoto),
        bottomNavigationBar: !_loaded
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<PhotoFit>(
                          showSelectedIcon: false,
                          segments: [
                            const ButtonSegment(
                              value: PhotoFit.fit,
                              label: Text('전체 보기'),
                            ),
                            const ButtonSegment(
                              value: PhotoFit.fill,
                              label: Text('꽉 채우기'),
                            ),
                            ButtonSegment(
                              value: PhotoFit.custom,
                              label: const Text('직접 맞추기'),
                              enabled: _exists,
                            ),
                          ],
                          selected: {_fit},
                          onSelectionChanged: (selected) =>
                              _changeFit(selected.single),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_fit == PhotoFit.custom && _exists)
                            TextButton.icon(
                              onPressed: _openCropEditor,
                              icon: const Icon(Icons.crop),
                              label: const Text('다시 맞추기'),
                            ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _changePhoto,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('사진 바꾸기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined, size: 56),
          const SizedBox(height: 12),
          const Text('위젯에 걸린 사진이 없어요'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onPick, child: const Text('사진 고르기')),
        ],
      ),
    );
  }
}
