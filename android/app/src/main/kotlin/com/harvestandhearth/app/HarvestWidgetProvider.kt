package com.harvestandhearth.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Color
import android.view.View
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
            try {
                val options = appWidgetManager.getAppWidgetOptions(widgetId)
                val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
                val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 260)
                val isCompact = minHeight < 120 || minWidth < 250
                val isUltraCompact = minHeight < 105 || minWidth < 220

                val views = RemoteViews(context.packageName, R.layout.harvest_widget).apply {
                val expiringCount = widgetData.getString("expiring_count", null)
                val expiredCountRaw = widgetData.getString("expired_count", "0") ?: "0"
                val expiredCount = expiredCountRaw.toIntOrNull() ?: 0
                val expiringCountNum = (expiringCount ?: "0").toIntOrNull() ?: 0
                val line1 = widgetData.getString("line1", "") ?: ""

                if (isCompact) {
                    setViewPadding(R.id.widget_root, 10, 10, 10, 10)
                    setTextViewTextSize(R.id.widget_title, 2, 14f)
                    setTextViewTextSize(R.id.widget_status_chip, 2, 10f)
                    setTextViewTextSize(R.id.widget_expiring_label, 2, 10f)
                    setTextViewTextSize(R.id.widget_expired_label, 2, 10f)
                    setTextViewTextSize(R.id.widget_expiring_value, 2, 19f)
                    setTextViewTextSize(R.id.widget_expired_value, 2, 19f)
                    setTextViewTextSize(R.id.widget_line2, 2, 11f)
                    setViewPadding(R.id.widget_status_chip, 8, 3, 8, 3)
                    setInt(R.id.widget_line2, "setMaxLines", 2)
                } else {
                    setViewPadding(R.id.widget_root, 14, 14, 14, 14)
                    setTextViewTextSize(R.id.widget_title, 2, 15f)
                    setTextViewTextSize(R.id.widget_status_chip, 2, 11f)
                    setTextViewTextSize(R.id.widget_expiring_label, 2, 11f)
                    setTextViewTextSize(R.id.widget_expired_label, 2, 11f)
                    setTextViewTextSize(R.id.widget_expiring_value, 2, 22f)
                    setTextViewTextSize(R.id.widget_expired_value, 2, 22f)
                    setTextViewTextSize(R.id.widget_line2, 2, 12f)
                    setViewPadding(R.id.widget_status_chip, 10, 4, 10, 4)
                    setInt(R.id.widget_line2, "setMaxLines", 3)
                }

                setImageViewResource(R.id.widget_app_icon, R.mipmap.ic_launcher)
                setTextViewText(R.id.widget_title, "Harvest & Hearth")
                setViewVisibility(
                    R.id.widget_app_icon,
                    if (isUltraCompact) View.GONE else View.VISIBLE,
                )

                val statusText = widgetData.getString("status_text", "") ?: ""
                if (isCompact && statusText.length > 16) {
                    setTextViewText(R.id.widget_status_chip, statusText.take(15) + "…")
                } else {
                    setTextViewText(R.id.widget_status_chip, statusText)
                }
                if (expiredCount > 0) {
                    setInt(
                        R.id.widget_root,
                        "setBackgroundResource",
                        R.drawable.widget_bg_danger,
                    )
                    setInt(
                        R.id.widget_status_chip,
                        "setBackgroundResource",
                        R.drawable.widget_status_danger,
                    )
                    setTextColor(R.id.widget_status_chip, Color.parseColor("#B71C1C"))
                } else if (expiringCountNum > 0) {
                    setInt(
                        R.id.widget_root,
                        "setBackgroundResource",
                        R.drawable.widget_bg_warning,
                    )
                    setInt(
                        R.id.widget_status_chip,
                        "setBackgroundResource",
                        R.drawable.widget_status_warning,
                    )
                    setTextColor(R.id.widget_status_chip, Color.parseColor("#E65100"))
                } else {
                    setInt(
                        R.id.widget_root,
                        "setBackgroundResource",
                        R.drawable.widget_bg_safe,
                    )
                    setInt(
                        R.id.widget_status_chip,
                        "setBackgroundResource",
                        R.drawable.widget_status_safe,
                    )
                    setTextColor(R.id.widget_status_chip, Color.parseColor("#14532D"))
                }

                val updatedAt = widgetData.getString("updated_at", "") ?: ""
                setTextViewText(R.id.widget_updated_at, updatedAt)
                setViewVisibility(
                    R.id.widget_updated_at,
                    if (isCompact) View.GONE else View.VISIBLE,
                )

                val subtitle = widgetData.getString("subtitle", "") ?: ""
                if (subtitle.isNotBlank() && !isCompact) {
                    setTextViewText(R.id.widget_subtitle, subtitle)
                    setViewVisibility(R.id.widget_subtitle, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_subtitle, View.GONE)
                }

                if (expiringCount == null && line1.isNotBlank()) {
                    setViewVisibility(R.id.widget_stats_row, View.GONE)
                    setViewVisibility(R.id.widget_legacy_line1, View.VISIBLE)
                    setTextViewText(R.id.widget_legacy_line1, line1)
                } else {
                    setViewVisibility(R.id.widget_legacy_line1, View.GONE)
                    setViewVisibility(R.id.widget_stats_row, View.VISIBLE)
                    setTextViewText(
                        R.id.widget_expiring_label,
                        widgetData.getString("label_expiring", "")?.takeIf { it.isNotBlank() }
                            ?: context.getString(R.string.widget_fallback_expiring),
                    )
                    setTextViewText(
                        R.id.widget_expiring_value,
                        expiringCount ?: "0",
                    )
                    setTextViewText(
                        R.id.widget_expired_label,
                        widgetData.getString("label_expired", "")?.takeIf { it.isNotBlank() }
                            ?: context.getString(R.string.widget_fallback_expired),
                    )
                    setTextViewText(
                        R.id.widget_expired_value,
                        expiredCountRaw,
                    )
                }

                setTextViewText(
                    R.id.widget_line2,
                    widgetData.getString("line2", "") ?: "",
                )
                setViewVisibility(
                    R.id.widget_line2,
                    if (isUltraCompact) View.GONE else View.VISIBLE,
                )

                val launchIntent = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
            }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (_: Exception) {
                // Keep widget alive with a minimal fallback to avoid "Can't load widget".
                val fallback = RemoteViews(context.packageName, R.layout.harvest_widget).apply {
                    setTextViewText(R.id.widget_title, "Harvest & Hearth")
                    setTextViewText(R.id.widget_status_chip, "Đang cập nhật")
                    setTextViewText(R.id.widget_expiring_value, "0")
                    setTextViewText(R.id.widget_expired_value, "0")
                    setTextViewText(R.id.widget_line2, "Mở app để đồng bộ lại")
                }
                appWidgetManager.updateAppWidget(widgetId, fallback)
            }
        }
    }
}
