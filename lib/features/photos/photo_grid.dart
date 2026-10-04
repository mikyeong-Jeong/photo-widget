import 'package:flutter/material.dart';

import '../../data/photo/saved_photo.dart';

/// 저장한 사진 3열 그리드. 앱 홈과 위젯 사진 고르기 화면에서 함께 쓴다.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    required this.onTap,
    this.onLongPress,
    this.selectedPath,
  });

  final List<SavedPhoto> photos;
  final ValueChanged<SavedPhoto> onTap;
  final ValueChanged<SavedPhoto>? onLongPress;

  /// 이 경로의 사진에 선택 표시를 한다.
  final String? selectedPath;

  @override
  Widget build(BuildContext context) {
    final cacheWidth =
        (MediaQuery.sizeOf(context).width /
                3 *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    final colors = Theme.of(context).colorScheme;

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
        final selected = photo.file.path == selectedPath;
        return GestureDetector(
          key: ValueKey(photo.id),
          onTap: () => onTap(photo),
          onLongPress: onLongPress == null ? null : () => onLongPress!(photo),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
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
              if (selected) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.primary, width: 3),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.check_circle,
                    color: colors.primary,
                    semanticLabel: '지금 위젯에 걸린 사진',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 사진이 하나도 없을 때.
class PhotoEmptyView extends StatelessWidget {
  const PhotoEmptyView({super.key, required this.title, required this.message});

  final String title;
  final String message;

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
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
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

/// 사진 목록을 불러오지 못했을 때.
class PhotoErrorView extends StatelessWidget {
  const PhotoErrorView({super.key, required this.onRetry});

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
