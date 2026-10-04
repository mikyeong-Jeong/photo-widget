import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo/saved_photo.dart';
import 'photo_list_controller.dart';

/// 지울지 물어보고, 확인하면 지운다. 지웠으면 true.
///
/// 이 사진을 보여주는 위젯이 있으면 함께 알려준다.
Future<bool> confirmAndDeletePhoto(
  BuildContext context,
  WidgetRef ref,
  SavedPhoto photo,
) async {
  final widgetCount = await ref
      .read(photoWidgetBridgeProvider)
      .countWidgetsShowing(photo);
  if (!context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('사진을 지울까요?'),
      content: Text(
        [
          '앱에 저장된 복사본만 지워지고, 갤러리 원본은 그대로 남아요.',
          if (widgetCount > 0)
            '\n홈 화면 위젯 $widgetCount개가 이 사진을 보여주고 있어요. '
                '지우면 위젯을 눌러 다른 사진을 골라야 해요.',
        ].join('\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('지우기'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  await ref.read(photoListProvider.notifier).remove(photo.id);
  return true;
}
