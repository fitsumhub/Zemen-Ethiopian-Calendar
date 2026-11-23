package com.ethiocal

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ethiocal/home_widget",
        )
        widgetChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgets" -> {
                    @Suppress("UNCHECKED_CAST")
                    val payload = call.arguments as? Map<*, *>
                    if (payload != null) {
                        EthioCalHomeWidgetProvider.savePayload(this, payload)
                    }
                    EthioCalHomeWidgetProvider.refreshAll(this)
                    result.success(true)
                }
                "requestPin" -> {
                    result.success(EthioCalHomeWidgetProvider.requestPin(this))
                }
                "widgetCount" -> {
                    result.success(EthioCalHomeWidgetProvider.widgetCount(this))
                }
                "getInitialDestination" -> {
                    val dest = intent?.getStringExtra("navigate_to")
                    result.success(dest)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val dest = intent.getStringExtra("navigate_to")
        if (dest != null) {
            widgetChannel?.invokeMethod("onDestinationChanged", dest)
        }
    }
}
