import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo/saved_photo.dart';
import '../photos/add_photos_button.dart';
import '../photos/photo_grid.dart';
import '../photos/photo_list_controller.dart';

/// 위젯에 걸 사진을 고른다.
///
/// 위젯을 처음 놓을 때와 위젯을 눌렀을 때 열린다. 고르지 않고 닫으면
/// 처음 놓는 위젯은 홈 화면에 추가되지 않고, 이미 있던 위젯은 그대로 둔다.
class WidgetConfigureScreen extends ConsumerStatefulWidget {
  const WidgetConfigureScreen({super.key});

  @override
  ConsumerState<WidgetConfigureScreen> createState() =>
      _WidgetConfigureScreenState();
}

class _WidgetConfigureScreenState extends ConsumerState<WidgetConfigureScreen> {
  int? _widgetId;
  String? _currentPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadWidget();
  }

  Future<void> _loadWidget() async {
    final bridge = ref.read(photoWidgetBridgeProvider);
    final widgetId = await bridge.configuringWidgetId();
    if (widgetId == null) {
      await SystemNavigator.pop();
      return;
    }
    final currentPath = await bridge.photoPathOf(widgetId);
    if (!mounted) return;
    setState(() {
      _widgetId = widgetId;
      _currentPath = currentPath;
    });
  }

  Future<void> _select(SavedPhoto photo) async {
    final widgetId = _widgetId;
    if (widgetId == null || _saving) return;
    setState(() => _saving = true);
    final bridge = ref.read(photoWidgetBridgeProvider);
    try {
      await bridge.assign(widgetId, photo);
      await bridge.finishConfigure();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위젯에 사진을 걸지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(photoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('위젯에 걸 사진 고르기'),
        leading: const CloseButton(onPressed: SystemNavigator.pop),
      ),
      body: _widgetId == null || _saving
          ? const Center(child: CircularProgressIndicator())
          : switch (photos) {
              AsyncData(value: final photos) when photos.isEmpty =>
                const PhotoEmptyView(
                  title: '저장한 사진이 없어요',
                  message: '사진 추가 버튼으로 갤러리에서 사진을 골라 주세요',
                ),
              AsyncData(value: final photos) => PhotoGrid(
                photos: photos,
                selectedPath: _currentPath,
                onTap: _select,
              ),
              AsyncError() => PhotoErrorView(
                onRetry: () => ref.invalidate(photoListProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
      floatingActionButton: _widgetId == null || _saving
          ? null
          : AddPhotosButton(
              // 한 장만 새로 골랐다면 바로 위젯에 건다.
              onAdded: (added) {
                if (added.length == 1) _select(added.single);
              },
            ),
    );
  }
}
