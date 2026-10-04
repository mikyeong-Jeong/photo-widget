import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/photo/gallery_picker.dart';
import '../../data/photo/photo_repository.dart';
import '../../data/photo/saved_photo.dart';
import '../../data/widget/photo_widget_bridge.dart';

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepository(getApplicationDocumentsDirectory),
);

final galleryPickerProvider = Provider<GalleryPicker>((ref) => GalleryPicker());

final photoWidgetBridgeProvider = Provider<PhotoWidgetBridge>(
  (ref) => PhotoWidgetBridge(),
);

final photoListProvider =
    AsyncNotifierProvider<PhotoListController, List<SavedPhoto>>(
      PhotoListController.new,
    );

class PhotoListController extends AsyncNotifier<List<SavedPhoto>> {
  PhotoRepository get _repository => ref.read(photoRepositoryProvider);

  @override
  Future<List<SavedPhoto>> build() => _repository.loadAll();

  /// 갤러리에서 사진을 골라 추가하고, 추가된 사진을 돌려준다. 실패하면 예외를 던진다.
  Future<List<SavedPhoto>> pickAndAdd() async {
    final paths = await ref.read(galleryPickerProvider).pickImages();
    if (paths.isEmpty) return const [];
    final updated = await _repository.add(paths);
    if (ref.mounted) state = AsyncData(updated);
    return updated.take(paths.length).toList();
  }

  Future<void> remove(String id) async {
    final updated = await _repository.remove(id);
    if (ref.mounted) state = AsyncData(updated);
    await ref.read(photoWidgetBridgeProvider).refreshAll();
  }
}
