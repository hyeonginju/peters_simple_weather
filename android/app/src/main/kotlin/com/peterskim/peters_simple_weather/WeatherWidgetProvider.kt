package com.peterskim.peters_simple_weather

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Medium weather widget: current weather + summary + 5 hourly slots. */
class WeatherWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.weather_widget).apply {
                WeatherWidgetBinder.bindCommon(context, this, widgetData)
                // Medium-only summary fields (with theme-aware colours)
                val hasData = widgetData.getString("w_has_data", "false") == "true"
                val isError = widgetData.getString("w_error", "false") == "true"
                if (hasData && !isError) {
                    val theme = WeatherWidgetBinder.themeFor(widgetData)
                    setTextColor(R.id.w_condition, theme.primary)
                    setTextColor(R.id.w_minmax, theme.secondary)
                    setTextColor(R.id.w_pop, theme.primary)
                    setTextViewText(R.id.w_condition, widgetData.getString("w_condition", "") ?: "")
                    setTextViewText(R.id.w_minmax, widgetData.getString("w_minmax", "") ?: "")
                    setTextViewText(R.id.w_pop, widgetData.getString("w_pop", "") ?: "")
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
