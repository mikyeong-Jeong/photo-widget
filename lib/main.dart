import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/widget_configure/widget_configure_app.dart';

void main() {
  runApp(const ProviderScope(child: PhotoWidgetApp()));
}

/// Android `WidgetConfigureActivity` 의 진입점. 위젯에 걸 사진 고르기 화면만 띄운다.
@pragma('vm:entry-point')
void widgetConfigureMain() {
  runApp(const ProviderScope(child: WidgetConfigureApp()));
}
