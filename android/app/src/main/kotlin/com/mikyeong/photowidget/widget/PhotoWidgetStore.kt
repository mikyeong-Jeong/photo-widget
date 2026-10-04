package com.mikyeong.photowidget.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin

/** 위젯에 사진을 보여주는 방식. */
enum class PhotoFit {
    /** 사진 전체가 보이게. 남는 공간은 흐린 배경으로 채운다. */
    FIT,

    /** 위젯을 꽉 채우게. 위젯 비율과 다르면 가운데를 기준으로 잘린다. */
    FILL,
}

/**
 * 위젯별 설정 (사진 파일 경로, 보여주는 방식).
 *
 * Flutter 쪽 `PhotoWidgetBridge` 가 home_widget 으로 같은 키에 저장한다.
 */
object PhotoWidgetStore {
    private fun pathKey(widgetId: Int) = "photo_widget.$widgetId.path"

    private fun fitKey(widgetId: Int) = "photo_widget.$widgetId.fit"

    fun photoPath(context: Context, widgetId: Int): String? =
        HomeWidgetPlugin.getData(context).getString(pathKey(widgetId), null)

    /** 저장된 값이 없으면 사진이 잘리지 않는 [PhotoFit.FIT]. */
    fun photoFit(context: Context, widgetId: Int): PhotoFit =
        when (HomeWidgetPlugin.getData(context).getString(fitKey(widgetId), null)) {
            "fill" -> PhotoFit.FILL
            else -> PhotoFit.FIT
        }

    fun clear(context: Context, widgetIds: IntArray) {
        HomeWidgetPlugin.getData(context).edit().apply {
            widgetIds.forEach {
                remove(pathKey(it))
                remove(fitKey(it))
            }
            apply()
        }
    }
}
