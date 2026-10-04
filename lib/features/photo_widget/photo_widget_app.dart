import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/widget/photo_widget_bridge.dart';
import '../photos/photo_list_controller.dart';
import 'widget_photo_picker_screen.dart';
import 'widget_photo_viewer_screen.dart';

/// 홈 화면 위젯에서 여는 앱. (Android `PhotoWidgetActivity`)
///
/// 위젯을 누르면 원본 사진 보기, 위젯을 놓거나 다시 설정하면 사진 고르기를 띄운다.
class WidgetScreensApp extends StatelessWidget {
  const WidgetScreensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '사진 위젯',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const _LaunchGate(),
    );
  }
}

class _LaunchGate extends ConsumerStatefulWidget {
  const _LaunchGate();

  @override
  ConsumerState<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<_LaunchGate> {
  WidgetLaunch? _launch;
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bridge = ref.read(photoWidgetBridgeProvider);
    final launch = await bridge.launch();
    if (launch == null) {
      await bridge.close();
      return;
    }
    final currentPath = await bridge.photoPathOf(launch.widgetId);
    if (!mounted) return;
    setState(() {
      _launch = launch;
      _currentPath = currentPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final launch = _launch;
    if (launch == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bridge = ref.read(photoWidgetBridgeProvider);
    return switch (launch.mode) {
      WidgetLaunchMode.view => WidgetPhotoViewerScreen(
        widgetId: launch.widgetId,
      ),
      WidgetLaunchMode.configure => WidgetPhotoPickerScreen(
        selectedPath: _currentPath,
        onClose: bridge.close,
        onPicked: (photo) async {
          await bridge.assign(launch.widgetId, photo);
          await bridge.finishConfigure();
        },
      ),
    };
  }
}
