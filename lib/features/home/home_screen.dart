import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../photo_detail/photo_detail_screen.dart';
import '../photos/add_photos_button.dart';
import '../photos/confirm_delete_dialog.dart';
import '../photos/photo_grid.dart';
import '../photos/photo_list_controller.dart';

/// 위젯에 걸 수 있도록 저장해 둔 사진 목록.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 위젯'),
        actions: [
          IconButton(
            tooltip: '위젯 추가 방법',
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHowToAddWidget(context),
          ),
        ],
      ),
      body: switch (photos) {
        AsyncData(value: final photos) when photos.isEmpty =>
          const PhotoEmptyView(
            title: '아직 위젯에 걸어둔 사진이 없어요',
            message: '사진 추가 버튼으로 갤러리에서 사진을 골라 보세요',
          ),
        AsyncData(value: final photos) => PhotoGrid(
          photos: photos,
          onTap: (photo) => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => PhotoDetailScreen(photo: photo),
            ),
          ),
          onLongPress: (photo) => confirmAndDeletePhoto(context, ref, photo),
        ),
        AsyncError() => PhotoErrorView(
          onRetry: () => ref.invalidate(photoListProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: const AddPhotosButton(),
    );
  }

  void _showHowToAddWidget(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('홈 화면에 위젯 추가하기'),
        content: const Text(
          '1. 홈 화면의 빈 곳을 길게 눌러요\n'
          '2. 위젯 → "사진 위젯" 에서 "사진" 을 끌어다 놓아요\n'
          '3. 뜨는 화면에서 걸어둘 사진을 골라요\n\n'
          '위젯을 길게 눌러 크기를 바꿀 수 있고, '
          '위젯을 누르면 다른 사진으로 바꿀 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
