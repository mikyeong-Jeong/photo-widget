import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo/saved_photo.dart';
import '../photos/add_photos_button.dart';
import '../photos/photo_grid.dart';
import '../photos/photo_list_controller.dart';

/// 위젯에 걸 사진을 고른다.
class WidgetPhotoPickerScreen extends ConsumerStatefulWidget {
  const WidgetPhotoPickerScreen({
    super.key,
    required this.onPicked,
    this.selectedPath,
    this.onClose,
  });

  /// 사진을 골랐을 때. 실패하면 예외를 던진다.
  final Future<void> Function(SavedPhoto photo) onPicked;

  /// 지금 위젯에 걸린 사진 경로. 선택 표시를 한다.
  final String? selectedPath;

  /// 닫기 버튼을 눌렀을 때. 없으면 이전 화면으로 돌아간다.
  final VoidCallback? onClose;

  @override
  ConsumerState<WidgetPhotoPickerScreen> createState() =>
      _WidgetPhotoPickerScreenState();
}

class _WidgetPhotoPickerScreenState
    extends ConsumerState<WidgetPhotoPickerScreen> {
  bool _saving = false;

  Future<void> _select(SavedPhoto photo) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onPicked(photo);
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
        leading: widget.onClose == null
            ? null
            : CloseButton(onPressed: widget.onClose),
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : switch (photos) {
              AsyncData(value: final photos) when photos.isEmpty =>
                const PhotoEmptyView(
                  title: '저장한 사진이 없어요',
                  message: '사진 추가 버튼으로 갤러리에서 사진을 골라 주세요',
                ),
              AsyncData(value: final photos) => PhotoGrid(
                photos: photos,
                selectedPath: widget.selectedPath,
                onTap: _select,
              ),
              AsyncError() => PhotoErrorView(
                onRetry: () => ref.invalidate(photoListProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
      floatingActionButton: _saving
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
