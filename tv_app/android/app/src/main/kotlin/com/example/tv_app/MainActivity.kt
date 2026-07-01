package com.example.tv_app

import android.app.AlarmManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var rootModeEnabled: Boolean = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        KioskManager.keepScreenAwake(this)
    }

    override fun onResume() {
        super.onResume()
        AppVisibility.isForeground = true
        KioskManager.enter(this, rootMode = rootModeEnabled)
    }

    override fun onPause() {
        AppVisibility.isForeground = false
        super.onPause()
    }

    override fun onStop() {
        super.onStop()
        scheduleRestart(30)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)

        if (hasFocus) {
            KioskManager.hideSystemUi(this)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RESTART_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleRestart" -> {
                    val delaySeconds = call.argument<Int>("delaySeconds") ?: 30
                    scheduleRestart(delaySeconds.coerceAtLeast(1))
                    result.success(null)
                }

                "cancelRestart" -> {
                    cancelRestart()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UPDATE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val apkPath = call.argument<String>("apkPath")
                    val preferRootInstall =
                        call.argument<Boolean>("preferRootInstall") ?: true

                    if (apkPath == null || apkPath.isBlank()) {
                        result.error("INVALID_APK_PATH", "APK path is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val startedInstall = ApkInstaller.install(
                            this,
                            apkPath,
                            preferRootInstall
                        )
                        result.success(startedInstall)
                    } catch (error: Exception) {
                        result.error(
                            "INSTALL_APK_FAILED",
                            error.message,
                            Log.getStackTraceString(error)
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            KIOSK_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startStayAlive" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val intervalSeconds = call.argument<Int>("intervalSeconds") ?: 30
                    val rootMode = call.argument<Boolean>("rootMode") ?: true
                    rootModeEnabled = rootMode

                    if (enabled) {
                        KeepAliveService.start(
                            this,
                            intervalSeconds.coerceAtLeast(10),
                            rootMode
                        )
                    } else {
                        KeepAliveService.stop(this)
                    }

                    result.success(null)
                }

                "stopStayAlive" -> {
                    KeepAliveService.stop(this)
                    result.success(null)
                }

                "enterKiosk" -> {
                    val rootMode = call.argument<Boolean>("rootMode") ?: true
                    rootModeEnabled = rootMode
                    KioskManager.enter(this, rootMode)
                    result.success(null)
                }

                "exitKiosk" -> {
                    KioskManager.exit(this)
                    result.success(null)
                }

                "isRootAvailable" -> result.success(RootTools.isRootAvailable())

                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleRestart(delaySeconds: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = AppLauncher.restartPendingIntent(this)
        val triggerAt = SystemClock.elapsedRealtime() + delaySeconds * 1000L

        try {
            if (
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                alarmManager.canScheduleExactAlarms()
            ) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
                return
            }

            alarmManager.set(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                triggerAt,
                pendingIntent
            )
        } catch (error: SecurityException) {
            Log.w(TAG, "Exact alarm denied; using inexact restart alarm", error)
            alarmManager.set(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                triggerAt,
                pendingIntent
            )
        }
    }

    private fun cancelRestart() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(AppLauncher.restartPendingIntent(this))
    }

    private companion object {
        const val RESTART_CHANNEL = "tv_ads_app/restart"
        const val UPDATE_CHANNEL = "tv_ads_app/update"
        const val KIOSK_CHANNEL = "tv_ads_app/kiosk"
        const val TAG = "MainActivity"
    }
}
