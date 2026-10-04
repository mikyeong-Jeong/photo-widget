import 'package:flutter/material.dart';

Future<bool> confirmDeletePhoto(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('사진을 지울까요?'),
      content: const Text('앱에 저장된 복사본만 지워지고, 갤러리 원본은 그대로 남아요.'),
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
  return confirmed ?? false;
}
