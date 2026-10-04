import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'widget_configure_screen.dart';

/// 홈 화면 위젯의 사진 고르기 화면만 띄우는 앱. (Android `WidgetConfigureActivity`)
class WidgetConfigureApp extends StatelessWidget {
  const WidgetConfigureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '위젯 사진 고르기',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const WidgetConfigureScreen(),
    );
  }
}
