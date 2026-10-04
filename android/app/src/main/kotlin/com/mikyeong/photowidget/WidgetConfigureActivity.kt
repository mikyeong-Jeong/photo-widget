package com.mikyeong.photowidget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity

/**
 * 위젯을 처음 놓을 때와 위젯을 눌렀을 때 뜨는 "사진 고르기" 화면.
 *
 * 메인 앱과 따로 Dart 의 `widgetConfigureMain` 을 실행한다.
 */
class WidgetConfigureActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String = "widgetConfigureMain"

    companion object {
        /** [widgetId] 위젯을 눌렀을 때 이 화면을 여는 PendingIntent. */
        fun pendingIntent(context: Context, widgetId: Int): PendingIntent {
            val intent =
                Intent(context, WidgetConfigureActivity::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_CONFIGURE
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
