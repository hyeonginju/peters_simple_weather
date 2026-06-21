package com.peterskim.peters_simple_weather

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Compact weather widget: current weather (icon + temp) beside 5 hourly slots. */
class WeatherWidgetSmallProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.weather_widget_small).apply {
                WeatherWidgetBinder.bindCommon(context, this, widgetData)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
