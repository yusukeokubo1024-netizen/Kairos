package com.kairos.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget showing today's schedules. Data is written from the
 * Flutter side (see lib/services/home_widget_service.dart) whenever the
 * calendar screen's schedule stream updates while the app is open — this
 * provider itself never talks to Firestore, it only re-renders whatever
 * string was last saved to widget storage.
 *
 * The saved "today_schedules" value is up to 5 lines, newline-separated,
 * each already formatted (time + title) and localized by the Flutter side.
 */
class TodayScheduleWidgetProvider : HomeWidgetProvider() {
    private val lineIds = intArrayOf(
        R.id.widget_line1,
        R.id.widget_line2,
        R.id.widget_line3,
        R.id.widget_line4,
        R.id.widget_line5,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val rawLines = widgetData.getString("today_schedules", null)
        val lines = rawLines?.split("\n")?.filter { it.isNotBlank() } ?: emptyList()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.today_schedule_widget)

            views.setViewVisibility(
                R.id.widget_empty,
                if (lines.isEmpty()) android.view.View.VISIBLE else android.view.View.GONE,
            )
            lineIds.forEachIndexed { index, viewId ->
                val text = lines.getOrNull(index)
                if (text != null) {
                    views.setTextViewText(viewId, text)
                    views.setViewVisibility(viewId, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(viewId, android.view.View.GONE)
                }
            }

            // Tapping the widget just opens the app (no deep link to a
            // specific screen in this v1).
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
