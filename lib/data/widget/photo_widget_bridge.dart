import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../photo/saved_photo.dart';

/// 위젯에 사진을 보여주는 방식.
enum PhotoFit {
  /// 사진 전체가 보이게. 남는 공간은 흐린 배경으로 채운다.
  fit,

  /// 위젯을 꽉 채우게. 위젯 비율과 다르면 가운데를 기준으로 잘린다.
  fill,

  /// 사용자가 확대·이동해서 맞춘 영역으로 채운다.
  custom,
}

/// 위젯 화면(`PhotoWidgetActivity`)이 열린 목적.
enum WidgetLaunchMode {
  /// 위젯을 눌러서 연 경우: 원본 사진 보기.
  view,

  /// 위젯을 놓거나 다시 설정하는 경우: 사진 고르기.
  configure,
}

class WidgetLaunch {
  const WidgetLaunch({
    required this.widgetId,
    required this.mode,
    this.widgetAspectRatio = 1,
  });

  final int widgetId;
  final WidgetLaunchMode mode;

  /// 홈 화면에서 위젯의 지금 가로/세로 비율. 직접 맞추기 화면의 틀 비율로 쓴다.
  final double widgetAspectRatio;
}

/// Flutter 앱 ↔ Android 홈 화면 위젯 연결.
///
/// 위젯별 설정을 home_widget 저장소에 `photo_widget.<위젯ID>.path` / `.fit` / `.crop` 으로 저장한다.
/// 키 형식은 Android `PhotoWidgetStore` 와 같아야 한다.
class PhotoWidgetBridge {
  static const _androidProvider =
      'com.mikyeong.photowidget.widget.PhotoWidgetProvider';
  static const _launchChannel = MethodChannel('photo_widget/launch');

  static String _pathKey(int widgetId) => 'photo_widget.$widgetId.path';
  static String _fitKey(int widgetId) => 'photo_widget.$widgetId.fit';
  static String _cropKey(int widgetId) => 'photo_widget.$widgetId.crop';

  /// 위젯 화면으로 열렸다면 어느 위젯에서 어떤 목적으로 열렸는지.
  Future<WidgetLaunch?> launch() async {
    final info = await _launchChannel.invokeMapMethod<String, Object?>(
      'getLaunch',
    );
    if (info == null) return null;
    final width = (info['widgetWidth'] as num?)?.toDouble() ?? 0;
    final height = (info['widgetHeight'] as num?)?.toDouble() ?? 0;
    return WidgetLaunch(
      widgetId: info['widgetId']! as int,
      mode: info['mode'] == 'view'
          ? WidgetLaunchMode.view
          : WidgetLaunchMode.configure,
      widgetAspectRatio: width > 0 && height > 0 ? width / height : 1,
    );
  }

  Future<String?> photoPathOf(int widgetId) =>
      HomeWidget.getWidgetData<String>(_pathKey(widgetId));

  /// 저장된 값이 없으면 사진이 잘리지 않는 [PhotoFit.fit].
  Future<PhotoFit> photoFitOf(int widgetId) async {
    final value = await HomeWidget.getWidgetData<String>(_fitKey(widgetId));
    return PhotoFit.values.firstWhere(
      (fit) => fit.name == value,
      orElse: () => PhotoFit.fit,
    );
  }

  /// 직접 맞춘 영역. 사진 크기에 대한 비율(0~1)이다.
  Future<Rect?> photoCropOf(int widgetId) async {
    final value = await HomeWidget.getWidgetData<String>(_cropKey(widgetId));
    return value == null ? null : decodeCrop(value);
  }

  /// [widgetId] 위젯에 [photo] 를 걸고 위젯을 다시 그린다.
  ///
  /// 직접 맞춘 영역은 이전 사진 기준이므로 지우고, 보기 방식이 직접 맞추기였다면 전체 보기로 돌린다.
  Future<void> assign(int widgetId, SavedPhoto photo) async {
    await HomeWidget.saveWidgetData<String>(
      _pathKey(widgetId),
      photo.file.path,
    );
    await HomeWidget.saveWidgetData<String>(_cropKey(widgetId), null);
    if (await photoFitOf(widgetId) == PhotoFit.custom) {
      await HomeWidget.saveWidgetData<String>(
        _fitKey(widgetId),
        PhotoFit.fit.name,
      );
    }
    await refreshAll();
  }

  /// 전체 보기 / 꽉 채우기로 바꾼다. 직접 맞추기는 [setCustomCrop] 을 쓴다.
  Future<void> setPhotoFit(int widgetId, PhotoFit fit) async {
    assert(fit != PhotoFit.custom, 'setCustomCrop 을 쓴다');
    await HomeWidget.saveWidgetData<String>(_fitKey(widgetId), fit.name);
    await refreshAll();
  }

  /// 직접 맞춘 영역 [crop] 으로 위젯을 채운다.
  Future<void> setCustomCrop(int widgetId, Rect crop) async {
    await HomeWidget.saveWidgetData<String>(
      _cropKey(widgetId),
      encodeCrop(crop),
    );
    await HomeWidget.saveWidgetData<String>(
      _fitKey(widgetId),
      PhotoFit.custom.name,
    );
    await refreshAll();
  }

  /// Android `PhotoWidgetStore.photoCrop` 과 같은 "left,top,right,bottom" 형식.
  static String encodeCrop(Rect crop) => [
    crop.left,
    crop.top,
    crop.right,
    crop.bottom,
  ].map((v) => v.clamp(0.0, 1.0).toStringAsFixed(5)).join(',');

  static Rect? decodeCrop(String value) {
    final parts = value
        .split(',')
        .map((p) => double.tryParse(p.trim()))
        .toList();
    if (parts.length != 4 || parts.contains(null)) return null;
    final [left, top, right, bottom] = parts.cast<double>();
    final rect = Rect.fromLTRB(left, top, right, bottom);
    final valid =
        rect.left >= 0 &&
        rect.top >= 0 &&
        rect.right <= 1 &&
        rect.bottom <= 1 &&
        rect.width > 0 &&
        rect.height > 0;
    return valid ? rect : null;
  }

  /// 사진 고르기를 마치고, 처음 놓는 위젯이라면 홈 화면에 추가를 확정한다.
  Future<void> finishConfigure() => HomeWidget.finishHomeWidgetConfigure();

  /// 위젯 화면을 닫는다. 처음 놓는 위젯이라면 추가가 취소된다.
  Future<void> close() => SystemNavigator.pop();

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
    } on MissingPluginException {
      // 위젯을 지원하지 않는 플랫폼에서는 무시한다.
    }
  }
}
