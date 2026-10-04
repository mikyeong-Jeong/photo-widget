package com.mikyeong.photowidget.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.mikyeong.photowidget.R
import com.mikyeong.photowidget.WidgetConfigureActivity

/**
 * 홈 화면 사진 위젯. 위젯마다 [PhotoWidgetStore] 에 저장된 사진을 꽉 채워 보여준다.
 *
 * 앱에서 사진을 고르거나 지우면 Flutter 쪽에서 갱신(onUpdate)을 요청한다.
 */
class PhotoWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { updateWidget(context, manager, it) }
    }

    /** 위젯 크기를 바꾸면 그 크기에 맞는 해상도로 다시 그린다. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, manager, appWidgetId)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        PhotoWidgetStore.clear(context, appWidgetIds)
    }

    companion object {
        /** 위젯 크기를 아직 모를 때 쓰는 크기 (2×2 정도). */
        private const val FALLBACK_SIZE_DP = 180

        /** 4×4 위젯도 이 정도면 충분히 선명하다. 더 크면 메모리만 쓴다. */
        private const val MAX_SIDE_PX = 1440

        fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.photo_widget)
            val path = PhotoWidgetStore.photoPath(context, widgetId)
            val bitmap = path?.let { loadBitmap(context, manager, widgetId, it) }

            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_photo, bitmap)
                views.setViewVisibility(R.id.widget_photo, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_photo, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_empty_text,
                    context.getString(if (path == null) R.string.widget_empty else R.string.widget_missing),
                )
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                WidgetConfigureActivity.pendingIntent(context, widgetId),
            )
            manager.updateAppWidget(widgetId, views)
        }

        private fun loadBitmap(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
            path: String,
        ) = try {
            val options = manager.getAppWidgetOptions(widgetId)
            val metrics = context.resources.displayMetrics
            fun px(dp: Int) =
                ((if (dp > 0) dp else FALLBACK_SIZE_DP) * metrics.density).toInt().coerceAtMost(MAX_SIDE_PX)

            PhotoBitmapLoader.load(
                path,
                targetWidth = px(options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH)),
                targetHeight = px(options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)),
                // 위젯에 보낼 수 있는 Bitmap 한도(화면 크기 × 4 × 1.5)보다 넉넉히 작게.
                maxBytes = 4L * metrics.widthPixels * metrics.heightPixels,
            )
        } catch (_: OutOfMemoryError) {
            null
        }
    }
}
