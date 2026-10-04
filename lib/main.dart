import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/widget/photo_widget_bridge.dart';
import 'features/photo_widget/photo_widget_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 앱을 업데이트한 뒤 처음 열 때 위젯도 새 코드로 다시 그린다.
  PhotoWidgetBridge().refreshAll();
  runApp(const ProviderScope(child: PhotoWidgetApp()));
}

/// Android `PhotoWidgetActivity` 의 진입점. 위젯 사진 보기 / 고르기 화면만 띄운다.
@pragma('vm:entry-point')
void widgetMain() {
  runApp(const ProviderScope(child: WidgetScreensApp()));
}
