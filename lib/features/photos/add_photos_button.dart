import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo/gallery_picker.dart';
import '../../data/photo/saved_photo.dart';
import 'photo_list_controller.dart';

/// 사진을 추가하는 버튼. 누르면 어디서 고를지(갤러리 앱 / 최근 사진) 묻는다.
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
    final source = await _chooseSource(context);
    if (source == null) return;
    try {
      final added = await ref
          .read(photoListProvider.notifier)
          .pickAndAdd(source);
      if (added.isEmpty) return;
      messenger.showSnackBar(
        SnackBar(content: Text('사진 ${added.length}장을 추가했어요')),
      );
      onAdded?.call(added);
    } catch (e) {
      final noGallery = e is PlatformException && e.code == 'no_gallery';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            noGallery
                ? '갤러리 앱을 찾지 못했어요. "최근 사진에서 고르기"를 써 주세요.'
                : '사진을 추가하지 못했어요. 다시 시도해 주세요.',
          ),
        ),
      );
    }
  }

  Future<PhotoSource?> _chooseSource(BuildContext context) {
    return showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_album_outlined),
              title: const Text('갤러리 앱에서 고르기'),
              subtitle: const Text('갤러리 앱의 앨범별로 찾아서 골라요'),
              onTap: () => Navigator.pop(context, PhotoSource.galleryApp),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('최근 사진에서 고르기'),
              subtitle: const Text('최근에 찍은 사진부터 보여줘요'),
              onTap: () => Navigator.pop(context, PhotoSource.recent),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
