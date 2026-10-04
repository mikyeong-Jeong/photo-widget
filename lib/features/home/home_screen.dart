import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo/saved_photo.dart';
import '../photo_detail/photo_detail_screen.dart';
import '../photos/confirm_delete_dialog.dart';
import '../photos/photo_list_controller.dart';

/// 위젯에 걸 수 있도록 저장해 둔 사진 목록.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('사진 위젯')),
      body: switch (photos) {
        AsyncData(value: final photos) when photos.isEmpty =>
          const _EmptyView(),
        AsyncData(value: final photos) => _PhotoGrid(photos: photos),
        AsyncError() => _ErrorView(
          onRetry: () => ref.invalidate(photoListProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPhotos(context, ref),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('사진 추가'),
      ),
    );
  }

  Future<void> _addPhotos(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ref.read(photoListProvider.notifier).pickAndAdd();
      if (count > 0) {
        messenger.showSnackBar(SnackBar(content: Text('사진 $count장을 추가했어요')));
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('사진을 추가하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }
}

class _PhotoGrid extends ConsumerWidget {
  const _PhotoGrid({required this.photos});

  final List<SavedPhoto> photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheWidth =
        (MediaQuery.sizeOf(context).width /
                3 *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          key: ValueKey(photo.id),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => PhotoDetailScreen(photo: photo),
            ),
          ),
          onLongPress: () async {
            if (await confirmDeletePhoto(context)) {
              await ref.read(photoListProvider.notifier).remove(photo.id);
            }
          },
          child: Hero(
            tag: photo.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                photo.file,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                errorBuilder: (_, _, _) => const _BrokenImage(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('아직 위젯에 걸어둔 사진이 없어요', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '사진 추가 버튼으로 갤러리에서 사진을 골라 보세요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('사진 목록을 불러오지 못했어요'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
