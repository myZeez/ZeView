package com.notiview.noti_view

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.provider.Settings
import android.service.notification.NotificationListenerService
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.notiview.noti_view.service.NotiForegroundService
import com.notiview.noti_view.service.NotiListenerService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "noti_view/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (isListenerEnabled()) {
            ContextCompat.startForegroundService(this, Intent(this, NotiForegroundService::class.java))
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isListenerEnabled" -> result.success(isListenerEnabled())
                "openListenerSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                "openBatteryOptimizationSettings" -> {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    result.success(null)
                }
                "requestRebind" -> {
                    result.success(
                        try {
                            NotificationListenerService.requestRebind(
                                ComponentName(this, NotiListenerService::class.java)
                            )
                            true
                        } catch (e: Exception) {
                            false
                        }
                    )
                }
                "startForegroundService" -> {
                    ContextCompat.startForegroundService(this, Intent(this, NotiForegroundService::class.java))
                    result.success(null)
                }
                "getDbPath" -> result.success(getDatabasePath("notiview_events.db").absolutePath)
                else -> result.notImplemented()
            }
        }
    }

    private fun isListenerEnabled(): Boolean =
        NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }
}
