package com.mikyeong.photowidget.widget

import android.content.Context
import android.graphics.RectF
import es.antonborri.home_widget.HomeWidgetPlugin

/** 위젯에 사진을 보여주는 방식. */
enum class PhotoFit {
    /** 사진 전체가 보이게. 남는 공간은 흐린 배경으로 채운다. */
    FIT,

    /** 위젯을 꽉 채우게. 위젯 비율과 다르면 가운데를 기준으로 잘린다. */
    FILL,

    /** 사용자가 확대·이동해서 맞춘 영역([PhotoWidgetStore.photoCrop])으로 채운다. */
    CUSTOM,
}

/**
 * 위젯별 설정 (사진 파일 경로, 보여주는 방식).
 *
 * Flutter 쪽 `PhotoWidgetBridge` 가 home_widget 으로 같은 키에 저장한다.
 */
object PhotoWidgetStore {
    private fun pathKey(widgetId: Int) = "photo_widget.$widgetId.path"

    private fun fitKey(widgetId: Int) = "photo_widget.$widgetId.fit"

    private fun cropKey(widgetId: Int) = "photo_widget.$widgetId.crop"

    fun photoPath(context: Context, widgetId: Int): String? =
        HomeWidgetPlugin.getData(context).getString(pathKey(widgetId), null)

    /** 저장된 값이 없으면 사진이 잘리지 않는 [PhotoFit.FIT]. */
    fun photoFit(context: Context, widgetId: Int): PhotoFit =
        when (HomeWidgetPlugin.getData(context).getString(fitKey(widgetId), null)) {
            "fill" -> PhotoFit.FILL
            "custom" -> PhotoFit.CUSTOM
            else -> PhotoFit.FIT
        }

    /**
     * 직접 맞춘 영역. 사진(방향 보정 후) 크기에 대한 비율 "left,top,right,bottom" (0~1).
     * 없거나 잘못된 값이면 null.
     */
    fun photoCrop(context: Context, widgetId: Int): RectF? {
        val raw = HomeWidgetPlugin.getData(context).getString(cropKey(widgetId), null) ?: return null
        val values = raw.split(",").mapNotNull { it.trim().toFloatOrNull() }
        if (values.size != 4) return null
        val rect = RectF(values[0], values[1], values[2], values[3])
        val valid = rect.left >= 0f && rect.top >= 0f && rect.right <= 1f && rect.bottom <= 1f &&
            rect.width() > 0f && rect.height() > 0f
        return if (valid) rect else null
    }

    fun clear(context: Context, widgetIds: IntArray) {
        HomeWidgetPlugin.getData(context).edit().apply {
            widgetIds.forEach {
                remove(pathKey(it))
                remove(fitKey(it))
                remove(cropKey(it))
            }
            apply()
        }
    }
}
