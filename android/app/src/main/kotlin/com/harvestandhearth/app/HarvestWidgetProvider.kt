package com.harvestandhearth.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HarvestWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.harvest_widget).apply {
                setTextViewText(R.id.widget_title, "Harvest & Hearth")
                setTextViewText(
                    R.id.widget_line1,
                    widgetData.getString("line1", "") ?: "",
                )
                setTextViewText(
                    R.id.widget_line2,
                    widgetData.getString("line2", "") ?: "",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
