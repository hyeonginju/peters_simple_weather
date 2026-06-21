package com.peterskim.peters_simple_weather

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Widget configuration Activity — launched when the widget is added and when
 * the user long-presses it and taps "설정" (reconfigurable). Boots the Flutter
 * app straight into the `/widget-settings` route; the Flutter screen calls the
 * `finish` method channel after saving, which returns RESULT_OK.
 */
class WidgetConfigActivity : FlutterActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        // Default to cancelled so backing out of first-time setup is safe.
        setResult(RESULT_CANCELED)
    }

    override fun getInitialRoute(): String = "/widget-settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "peters_weather/widget_config")
            .setMethodCallHandler { call, result ->
                if (call.method == "finish") {
                    val data = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    setResult(RESULT_OK, data)
                    result.success(null)
                    finish()
                } else {
                    result.notImplemented()
                }
            }
    }
}
