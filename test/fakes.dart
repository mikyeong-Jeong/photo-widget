import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_widget/data/photo/gallery_picker.dart';
import 'package:photo_widget/data/photo/photo_repository.dart';
import 'package:photo_widget/data/photo/saved_photo.dart';
import 'package:photo_widget/data/widget/photo_widget_bridge.dart';
import 'package:photo_widget/features/photos/photo_list_controller.dart';

/// 파일 시스템 없이 동작하는 저장소.
class FakePhotoRepository implements PhotoRepository {
  FakePhotoRepository([List<SavedPhoto>? photos]) : photos = photos ?? [];

  List<SavedPhoto> photos;

  @override
  Future<List<SavedPhoto>> loadAll() async => photos;

  @override
  Future<List<SavedPhoto>> add(List<String> sourcePaths) async {
    return photos = [
      for (final path in sourcePaths) fakePhoto(path),
      ...photos,
    ];
  }

  @override
  Future<List<SavedPhoto>> remove(String id) async {
    return photos = [
      for (final p in photos)
        if (p.id != id) p,
    ];
  }
}

class FakeGalleryPicker implements GalleryPicker {
  FakeGalleryPicker(this.result);

  final List<String> result;

  @override
  Future<List<String>> pickImages() async => result;
}

/// 홈 화면 위젯 대신 위젯 ID → 사진 경로를 메모리에 들고 있는다.
class FakePhotoWidgetBridge implements PhotoWidgetBridge {
  FakePhotoWidgetBridge({this.widgetId, Map<int, String>? paths})
    : paths = paths ?? {};

  final int? widgetId;
  final Map<int, String> paths;
  bool finished = false;
  int refreshCount = 0;

  @override
  Future<int?> configuringWidgetId() async => widgetId;

  @override
  Future<String?> photoPathOf(int widgetId) async => paths[widgetId];

  @override
  Future<void> assign(int widgetId, SavedPhoto photo) async {
    paths[widgetId] = photo.file.path;
    refreshCount++;
  }

  @override
  Future<void> finishConfigure() async => finished = true;

  @override
  Future<int> countWidgetsShowing(SavedPhoto photo) async =>
      paths.values.where((p) => p == photo.file.path).length;

  @override
  Future<void> refreshAll() async => refreshCount++;
}

SavedPhoto fakePhoto(String id) => SavedPhoto(
  id: id,
  file: File('/nonexistent/$id.jpg'),
  addedAt: DateTime(2026),
);

Widget testApp({
  required Widget child,
  required PhotoRepository repository,
  PhotoWidgetBridge? bridge,
  List<String> picked = const [],
}) {
  return ProviderScope(
    overrides: [
      photoRepositoryProvider.overrideWithValue(repository),
      galleryPickerProvider.overrideWithValue(FakeGalleryPicker(picked)),
      photoWidgetBridgeProvider.overrideWithValue(
        bridge ?? FakePhotoWidgetBridge(),
      ),
    ],
    child: child,
  );
}
