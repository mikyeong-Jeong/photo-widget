package com.mikyeong.photowidget.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.RectF
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.mikyeong.photowidget.R
import com.mikyeong.photowidget.PhotoWidgetActivity

/**
 * 홈 화면 사진 위젯. 위젯마다 [PhotoWidgetStore] 에 저장된 사진을 저장된 방식(전체 보기 / 꽉 채우기 / 직접 맞추기)으로 보여준다.
 *
 * 위젯을 누르면 원본 사진 보기 화면이 열린다.
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

        private const val BACKDROP_ALPHA = 140

        fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.photo_widget)
            val path = PhotoWidgetStore.photoPath(context, widgetId)
            val savedFit = PhotoWidgetStore.photoFit(context, widgetId)
            val crop = if (savedFit == PhotoFit.CUSTOM) PhotoWidgetStore.photoCrop(context, widgetId) else null
            // 맞춘 영역이 없으면 꽉 채우기로 보여준다.
            val fit = if (savedFit == PhotoFit.CUSTOM && crop == null) PhotoFit.FILL else savedFit
            val bitmap = path?.let { loadBitmap(context, manager, widgetId, it, crop) }
            val photoViews = listOf(R.id.widget_photo_backdrop, R.id.widget_photo_fit, R.id.widget_photo_fill)
            photoViews.forEach { views.setViewVisibility(it, View.GONE) }

            if (bitmap == null) {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_empty_text,
                    context.getString(if (path == null) R.string.widget_empty else R.string.widget_missing),
                )
            } else {
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                when (fit) {
                    // 직접 맞춘 영역은 이미 잘라서 읽었다. 위젯 비율이 바뀌었으면 그 가운데를 기준으로 채운다.
                    PhotoFit.FILL, PhotoFit.CUSTOM -> {
                        views.setImageViewBitmap(R.id.widget_photo_fill, bitmap)
                        views.setViewVisibility(R.id.widget_photo_fill, View.VISIBLE)
                    }
                    PhotoFit.FIT -> {
                        views.setImageViewBitmap(R.id.widget_photo_backdrop, blurredBackdrop(bitmap))
                        // 배경은 살짝 비치게 해서 사진과 구분되게 한다.
                        views.setInt(R.id.widget_photo_backdrop, "setImageAlpha", BACKDROP_ALPHA)
                        views.setViewVisibility(R.id.widget_photo_backdrop, View.VISIBLE)
                        views.setImageViewBitmap(R.id.widget_photo_fit, bitmap)
                        views.setViewVisibility(R.id.widget_photo_fit, View.VISIBLE)
                    }
                }
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PhotoWidgetActivity.viewPhotoIntent(context, widgetId),
            )
            manager.updateAppWidget(widgetId, views)
        }

        /**
         * 사진을 아주 작게 줄였다가 다시 키워서 흐린 배경을 만든다.
         * 작은 Bitmap 이라 위젯 메모리 한도에도 거의 영향이 없다.
         */
        private fun blurredBackdrop(photo: Bitmap): Bitmap {
            val ratio = photo.height.toFloat() / photo.width
            val tiny = Bitmap.createScaledBitmap(photo, 12, (12 * ratio).toInt().coerceAtLeast(1), true)
            val soft = Bitmap.createScaledBitmap(tiny, 96, (96 * ratio).toInt().coerceAtLeast(1), true)
            if (soft !== tiny) tiny.recycle()
            return soft
        }

        /** [photo] 에서 비율 영역 [crop] 만 잘라낸다. */
        private fun cropTo(photo: Bitmap, crop: RectF): Bitmap {
            val left = (crop.left * photo.width).toInt().coerceIn(0, photo.width - 1)
            val top = (crop.top * photo.height).toInt().coerceIn(0, photo.height - 1)
            val width = (crop.width() * photo.width).toInt().coerceIn(1, photo.width - left)
            val height = (crop.height() * photo.height).toInt().coerceIn(1, photo.height - top)
            val cropped = Bitmap.createBitmap(photo, left, top, width, height)
            if (cropped !== photo) photo.recycle()
            return cropped
        }

        private fun loadBitmap(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
            path: String,
            crop: RectF?,
        ) = try {
            val options = manager.getAppWidgetOptions(widgetId)
            val metrics = context.resources.displayMetrics
            fun px(dp: Int) =
                ((if (dp > 0) dp else FALLBACK_SIZE_DP) * metrics.density).toInt().coerceAtMost(MAX_SIDE_PX)

            val targetWidth = px(options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH))
            val targetHeight = px(options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT))
            // 맞춘 영역만 위젯 크기가 되도록, 사진 전체는 그만큼 더 크게 읽는다.
            val photo =
                PhotoBitmapLoader.load(
                    path,
                    targetWidth = (targetWidth / (crop?.width() ?: 1f)).toInt(),
                    targetHeight = (targetHeight / (crop?.height() ?: 1f)).toInt(),
                    // 위젯에 보낼 수 있는 Bitmap 한도(화면 크기 × 4 × 1.5)보다 넉넉히 작게.
                    maxBytes = 4L * metrics.widthPixels * metrics.heightPixels,
                )
            if (photo == null || crop == null) photo else cropTo(photo, crop)
        } catch (_: OutOfMemoryError) {
            null
        }
    }
}
