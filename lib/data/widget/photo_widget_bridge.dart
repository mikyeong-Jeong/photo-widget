import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../photo/saved_photo.dart';

/// Flutter 앱 ↔ Android 홈 화면 위젯 연결.
///
/// 위젯마다 보여줄 사진 경로를 home_widget 저장소에 `photo_widget.<위젯ID>.path` 로 저장한다.
/// 키 형식은 Android `PhotoWidgetStore` 와 같아야 한다.
class PhotoWidgetBridge {
  static const _androidProvider =
      'com.mikyeong.photowidget.widget.PhotoWidgetProvider';

  static String _pathKey(int widgetId) => 'photo_widget.$widgetId.path';

  /// 위젯 설정 화면으로 열렸다면 그 위젯의 ID.
  Future<int?> configuringWidgetId() async {
    final id = await HomeWidget.initiallyLaunchedFromHomeWidgetConfigure();
    return id == null ? null : int.tryParse(id);
  }

  Future<String?> photoPathOf(int widgetId) =>
      HomeWidget.getWidgetData<String>(_pathKey(widgetId));

  /// [widgetId] 위젯에 [photo] 를 걸고 위젯을 다시 그린다.
  Future<void> assign(int widgetId, SavedPhoto photo) async {
    await HomeWidget.saveWidgetData<String>(
      _pathKey(widgetId),
      photo.file.path,
    );
    await refreshAll();
  }

  /// 설정 화면을 닫고, 처음 놓는 위젯이라면 홈 화면에 추가를 확정한다.
  Future<void> finishConfigure() => HomeWidget.finishHomeWidgetConfigure();

  /// [photo] 를 보여주고 있는 위젯 개수.
  Future<int> countWidgetsShowing(SavedPhoto photo) async {
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      var count = 0;
      for (final widget in widgets) {
        final id = widget.androidWidgetId;
        if (id != null && await photoPathOf(id) == photo.file.path) count++;
      }
      return count;
    } on PlatformException {
      return 0;
    }
  }

  /// 모든 사진 위젯을 다시 그린다. (사진이 지워졌으면 "다시 선택" 안내로 바뀐다)
  Future<void> refreshAll() async {
    try {
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
    } on PlatformException {
      // 위젯을 지원하지 않는 플랫폼에서는 무시한다.
    }
  }
}
