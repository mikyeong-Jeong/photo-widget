import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo/saved_photo.dart';
import '../photos/confirm_delete_dialog.dart';

/// 홈 화면 위젯의 대표적인 모양. (가로 칸 x 세로 칸)
enum WidgetShape {
  small('2×2', 1),
  wide('4×2', 2),
  tall('2×4', 0.5),
  large('4×4', 1);

  const WidgetShape(this.label, this.aspectRatio);

  final String label;
  final double aspectRatio;
}

/// 사진 한 장을 크게 보고, 위젯 크기별로 어떻게 잘려 보일지 미리 본다.
class PhotoDetailScreen extends ConsumerWidget {
  const PhotoDetailScreen({super.key, required this.photo});

  final SavedPhoto photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: '지우기',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await confirmAndDeletePhoto(context, ref, photo)) {
                navigator.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: photo.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(photo.file, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 24),
          Text('위젯 크기별 미리보기', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '위젯 보기 방식을 "꽉 채우기"로 하면 이렇게 가운데를 기준으로 잘려 보여요. "전체 보기"(기본)는 잘리지 않아요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final shape in WidgetShape.values) ...[
                  _ShapePreview(photo: photo, shape: shape),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapePreview extends StatelessWidget {
  const _ShapePreview({required this.photo, required this.shape});

  final SavedPhoto photo;
  final WidgetShape shape;

  @override
  Widget build(BuildContext context) {
    // 2칸 = 48, 4칸 = 96 정도로 축소해서 보여준다.
    final height = shape == WidgetShape.tall || shape == WidgetShape.large
        ? 96.0
        : 48.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: height * shape.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(photo.file, fit: BoxFit.cover, cacheWidth: 300),
          ),
        ),
        const SizedBox(height: 6),
        Text(shape.label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
