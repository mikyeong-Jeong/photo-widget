package com.mikyeong.photowidget.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * 위젯 ID → 사진 파일 경로.
 *
 * Flutter 쪽 `PhotoWidgetBridge` 가 home_widget 으로 같은 키에 저장한다.
 */
object PhotoWidgetStore {
    private fun key(widgetId: Int) = "photo_widget.$widgetId.path"

    fun photoPath(context: Context, widgetId: Int): String? =
        HomeWidgetPlugin.getData(context).getString(key(widgetId), null)

    fun clear(context: Context, widgetIds: IntArray) {
        HomeWidgetPlugin.getData(context).edit().apply {
            widgetIds.forEach { remove(key(it)) }
            apply()
        }
    }
}
