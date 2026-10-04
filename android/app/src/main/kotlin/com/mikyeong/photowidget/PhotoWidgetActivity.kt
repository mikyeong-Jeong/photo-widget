package com.mikyeong.photowidget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import com.mikyeong.photowidget.gallery.GalleryAppPicker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 홈 화면 위젯에서 여는 Flutter 화면. 메인 앱과 따로 Dart 의 `widgetMain` 을 실행한다.
 *
 * - 위젯을 눌렀을 때 ([ACTION_VIEW_PHOTO]): 위젯에 걸린 원본 사진 보기
 * - 위젯을 놓을 때 / 다시 설정할 때 (APPWIDGET_CONFIGURE): 위젯에 걸 사진 고르기
 */
class PhotoWidgetActivity : FlutterActivity() {
    private val galleryAppPicker = GalleryAppPicker(this)

    override fun getDartEntrypointFunctionName(): String = "widgetMain"

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!galleryAppPicker.onActivityResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        galleryAppPicker.register(flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunch" -> result.success(launchInfo())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 어느 위젯에서 어떤 목적으로 열렸는지와 위젯의 지금 크기(dp). 위젯 ID 가 없으면 null.
     *
     * 위젯 크기는 직접 맞추기 화면의 틀 비율로 쓴다.
     */
    private fun launchInfo(): Map<String, Any>? {
        val widgetId =
            intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            )
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return null
        val mode = if (intent.action == ACTION_VIEW_PHOTO) "view" else "configure"

        // 세로 화면에서는 (최소 너비 × 최대 높이), 가로 화면에서는 (최대 너비 × 최소 높이)가 실제 크기다.
        val options = AppWidgetManager.getInstance(this).getAppWidgetOptions(widgetId)
        val landscape = resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val width =
            options.getInt(
                if (landscape) AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
            )
        val height =
            options.getInt(
                if (landscape) AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT,
            )
        return mapOf("widgetId" to widgetId, "mode" to mode, "widgetWidth" to width, "widgetHeight" to height)
    }

    companion object {
        private const val LAUNCH_CHANNEL = "photo_widget/launch"
        private const val ACTION_VIEW_PHOTO = "com.mikyeong.photowidget.action.VIEW_PHOTO"

        /** [widgetId] 위젯을 눌렀을 때 사진 보기 화면을 여는 PendingIntent. */
        fun viewPhotoIntent(context: Context, widgetId: Int): PendingIntent {
            val intent =
                Intent(context, PhotoWidgetActivity::class.java).apply {
                    action = ACTION_VIEW_PHOTO
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    // 위젯마다 다른 PendingIntent 가 되도록 data 를 구분한다.
                    data = Uri.parse("photowidget://widget/$widgetId")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
            return PendingIntent.getActivity(
                context,
                widgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
