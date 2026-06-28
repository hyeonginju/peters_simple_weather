package com.peterskim.peters_simple_weather

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/** Text colours for the chosen background style. */
data class WidgetTheme(val primary: Int, val secondary: Int)

/** Shared binding for both the medium and small weather widgets. */
object WeatherWidgetBinder {

    /** Resolves text colours from the saved background style (light bg needs
     * dark text). Used by [bindCommon] and by the medium provider for its
     * extra summary fields. */
    fun themeFor(data: SharedPreferences): WidgetTheme {
        val light = data.getString("w_bg_style", "medium") == "light"
        return if (light) {
            WidgetTheme(primary = 0xFF16181C.toInt(), secondary = 0xFF8A9098.toInt())
        } else {
            WidgetTheme(primary = 0xFFFFFFFF.toInt(), secondary = 0xB3FFFFFF.toInt())
        }
    }

    private fun applyBackground(views: RemoteViews, data: SharedPreferences) {
        val bg = when (data.getString("w_bg_style", "medium")) {
            "dark" -> R.drawable.widget_bg_dark
            "light" -> R.drawable.widget_bg_light
            else -> R.drawable.widget_bg_medium
        }
        views.setImageViewResource(R.id.widget_bg, bg)
        val opacity = (data.getString("w_bg_opacity", "100") ?: "100").toIntOrNull() ?: 100
        views.setInt(R.id.widget_bg, "setImageAlpha", (opacity * 255 / 100).coerceIn(0, 255))
    }

    /** Binds the parts common to every widget size. Medium-only fields
     * (condition/min-max/pop) are set by the caller afterwards. */
    fun bindCommon(context: Context, views: RemoteViews, data: SharedPreferences) {
        applyBackground(views, data)

        val theme = themeFor(data)
        // Common text colours (medium-only fields handled by its provider).
        for (id in listOf(R.id.w_region, R.id.w_temp, R.id.widget_message,
                R.id.h0_temp, R.id.h1_temp, R.id.h2_temp, R.id.h3_temp, R.id.h4_temp)) {
            views.setTextColor(id, theme.primary)
        }
        for (id in listOf(R.id.w_updated,
                R.id.h0_label, R.id.h1_label, R.id.h2_label, R.id.h3_label, R.id.h4_label)) {
            views.setTextColor(id, theme.secondary)
        }
        views.setInt(R.id.w_dot, "setColorFilter", theme.primary)
        views.setInt(R.id.w_refresh, "setColorFilter", theme.primary)

        // Tap body -> open app
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
        // Tap refresh (enlarged touch target around the icon) -> background
        // Dart callback (no app launch)
        views.setOnClickPendingIntent(
            R.id.w_refresh_touch,
            HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("clean-weather://refresh")),
        )

        // Loading spinner toggle
        val loading = data.getString("w_loading", "false") == "true"
        views.setViewVisibility(R.id.w_refresh, if (loading) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.w_progress, if (loading) View.VISIBLE else View.GONE)

        val hasData = data.getString("w_has_data", "false") == "true"
        val isError = data.getString("w_error", "false") == "true"

        if (!hasData) {
            views.setViewVisibility(R.id.widget_content, View.GONE)
            views.setViewVisibility(R.id.widget_message, View.VISIBLE)
            views.setTextViewText(R.id.w_region, "")
            views.setTextViewText(R.id.w_updated, "")
            views.setTextViewText(R.id.widget_message, "지역을 추가해 주세요")
            return
        }

        views.setTextViewText(R.id.w_region, data.getString("w_region", "") ?: "")

        if (isError) {
            views.setViewVisibility(R.id.widget_content, View.GONE)
            views.setViewVisibility(R.id.widget_message, View.VISIBLE)
            views.setTextViewText(R.id.w_updated, "업데이트 실패")
            views.setTextViewText(R.id.widget_message, "데이터를 불러오지 못했습니다\n다시 시도해 주세요")
            return
        }

        views.setViewVisibility(R.id.widget_content, View.VISIBLE)
        views.setViewVisibility(R.id.widget_message, View.GONE)

        views.setTextViewText(R.id.w_updated, data.getString("w_updated", "") ?: "")
        views.setTextViewText(R.id.w_temp, data.getString("w_temp", "") ?: "")
        views.setImageViewResource(R.id.w_icon, iconRes(data.getString("w_icon", "sun")))

        bindHour(views, data, 0, R.id.h0_label, R.id.h0_icon, R.id.h0_temp)
        bindHour(views, data, 1, R.id.h1_label, R.id.h1_icon, R.id.h1_temp)
        bindHour(views, data, 2, R.id.h2_label, R.id.h2_icon, R.id.h2_temp)
        bindHour(views, data, 3, R.id.h3_label, R.id.h3_icon, R.id.h3_temp)
        bindHour(views, data, 4, R.id.h4_label, R.id.h4_icon, R.id.h4_temp)
    }

    private fun bindHour(
        views: RemoteViews,
        data: SharedPreferences,
        index: Int,
        labelId: Int,
        iconId: Int,
        tempId: Int,
    ) {
        val label = data.getString("w_h${index}_label", "") ?: ""
        if (label.isEmpty()) {
            views.setViewVisibility(labelId, View.INVISIBLE)
            views.setViewVisibility(iconId, View.INVISIBLE)
            views.setViewVisibility(tempId, View.INVISIBLE)
            return
        }
        views.setViewVisibility(labelId, View.VISIBLE)
        views.setViewVisibility(iconId, View.VISIBLE)
        views.setViewVisibility(tempId, View.VISIBLE)
        views.setTextViewText(labelId, label)
        views.setTextViewText(tempId, data.getString("w_h${index}_temp", "") ?: "")
        views.setImageViewResource(iconId, iconRes(data.getString("w_h${index}_icon", "sun")))
    }

    fun iconRes(key: String?): Int = when (key) {
        "partly" -> R.drawable.ic_w_partly
        "cloud" -> R.drawable.ic_w_cloud
        "rain" -> R.drawable.ic_w_rain
        "snow" -> R.drawable.ic_w_snow
        else -> R.drawable.ic_w_sun
    }
}
