import 'package:flutter/material.dart';

/// 위젯에 걸어둔 사진 목록을 보여줄 첫 화면. (1단계에서 구현)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사진 위젯')),
      body: const Center(
        child: Text('아직 위젯에 걸어둔 사진이 없어요'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('사진 추가'),
      ),
    );
  }
}
