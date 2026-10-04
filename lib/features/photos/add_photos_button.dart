import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo/saved_photo.dart';
import 'photo_list_controller.dart';

/// 갤러리에서 사진을 골라 추가하는 버튼.
class AddPhotosButton extends ConsumerWidget {
  const AddPhotosButton({super.key, this.onAdded});

  /// 사진을 한 장 이상 추가했을 때 추가된 사진과 함께 불린다.
  final ValueChanged<List<SavedPhoto>>? onAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _addPhotos(context, ref),
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text('사진 추가'),
    );
  }

  Future<void> _addPhotos(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final added = await ref.read(photoListProvider.notifier).pickAndAdd();
      if (added.isEmpty) return;
      messenger.showSnackBar(
        SnackBar(content: Text('사진 ${added.length}장을 추가했어요')),
      );
      onAdded?.call(added);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('사진을 추가하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }
}
