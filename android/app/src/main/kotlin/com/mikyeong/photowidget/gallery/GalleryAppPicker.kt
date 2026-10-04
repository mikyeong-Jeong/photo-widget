package com.mikyeong.photowidget.gallery

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import com.mikyeong.photowidget.widget.PhotoBitmapLoader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * 폰의 갤러리 앱(삼성 갤러리 등)을 열어 사진을 고른다. 갤러리 앱의 앨범 구조를 그대로 쓸 수 있다.
 *
 * 고른 사진은 긴 변 [MAX_SIDE] px 로 줄이고 방향을 바로잡은 JPEG 로 캐시에 만들어 경로를 돌려준다.
 * (시스템 사진 선택기로 고를 때와 같은 결과)
 *
 * Flutter Activity 에서 [register] 하고, onActivityResult 를 [onActivityResult] 로 넘겨야 한다.
 */
class GalleryAppPicker(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFromGalleryApp" -> pick(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pick(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "이미 사진을 고르는 중이에요", null)
            return
        }
        val galleryIntent =
            Intent(Intent.ACTION_PICK).apply {
                setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*")
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        // 갤러리 앱이 없으면 파일 선택 화면으로 연다.
        val fallbackIntent =
            Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "image/*"
                addCategory(Intent.CATEGORY_OPENABLE)
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        for (intent in listOf(galleryIntent, fallbackIntent)) {
            try {
                activity.startActivityForResult(intent, REQUEST_CODE)
                pending = result
                return
            } catch (_: ActivityNotFoundException) {
                // 다음 방법으로
            }
        }
        result.error("no_gallery", "사진을 고를 수 있는 앱이 없어요", null)
    }

    /** 이 클래스가 연 화면의 결과면 처리하고 true. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending ?: return true
        pending = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return true
        }
        val uris = buildList {
            data.clipData?.let { clip ->
                for (i in 0 until clip.itemCount) add(clip.getItemAt(i).uri)
            }
            if (isEmpty()) data.data?.let { add(it) }
        }
        executor.execute {
            try {
                val paths = prepare(uris)
                mainHandler.post { result.success(paths) }
            } catch (e: Exception) {
                mainHandler.post { result.error("read_failed", e.message, null) }
            }
        }
        return true
    }

    /** 고른 사진들을 앱이 읽을 수 있는 크기 줄인 JPEG 파일로 만든다. 읽지 못한 사진은 뺀다. */
    private fun prepare(uris: List<Uri>): List<String> {
        val dir = File(activity.cacheDir, "gallery_pick").apply {
            deleteRecursively()
            mkdirs()
        }
        return uris.mapIndexedNotNull { i, uri ->
            val original = File(dir, "original_$i")
            val copied =
                activity.contentResolver.openInputStream(uri)?.use { input ->
                    original.outputStream().use { input.copyTo(it) }
                }
            if (copied == null) return@mapIndexedNotNull null

            val bitmap =
                try {
                    PhotoBitmapLoader.loadFitting(original.path, MAX_SIDE)
                } catch (_: OutOfMemoryError) {
                    null
                }
            original.delete()
            if (bitmap == null) return@mapIndexedNotNull null

            val photo = File(dir, "photo_$i.jpg")
            photo.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, it) }
            bitmap.recycle()
            photo.path
        }
    }

    companion object {
        private const val CHANNEL = "photo_widget/gallery"
        private const val REQUEST_CODE = 0x6A11

        /** Flutter 쪽 GalleryPicker.maxDimension 과 같게. */
        private const val MAX_SIDE = 1600
        private const val JPEG_QUALITY = 90
    }
}
