package com.example.tv_app

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log

class KeepAliveService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var intervalMs: Long = DEFAULT_INTERVAL_MS
    private var rootMode: Boolean = true

    private val watchdogRunnable = object : Runnable {
        override fun run() {
            if (!AppVisibility.isForeground) {
                AppLauncher.launch(applicationContext, preferRoot = rootMode)
            }

            handler.postDelayed(this, intervalMs)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intervalMs = (intent?.getIntExtra(EXTRA_INTERVAL_SECONDS, 30) ?: 30)
            .coerceAtLeast(10) * 1000L
        rootMode = intent?.getBooleanExtra(EXTRA_ROOT_MODE, true) ?: true

        handler.removeCallbacks(watchdogRunnable)
        handler.postDelayed(watchdogRunnable, intervalMs)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(watchdogRunnable)
        releaseWakeLock()
        super.onDestroy()
    }

    @SuppressLint("WakelockTimeout")
    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "$packageName:KeepAliveService"
            )
            wakeLock?.acquire()
        } catch (error: Exception) {
            Log.d(TAG, "Unable to acquire wake lock", error)
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (error: Exception) {
            Log.d(TAG, "Unable to release wake lock", error)
        } finally {
            wakeLock = null
        }
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("TV Ads đang chạy")
            .setContentText("Đang giữ ứng dụng phát quảng cáo hoạt động.")
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "TV Ads Stay Alive",
            NotificationManager.IMPORTANCE_LOW
        )
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val TAG = "KeepAliveService"
        private const val CHANNEL_ID = "tv_ads_stay_alive"
        private const val NOTIFICATION_ID = 2001
        private const val DEFAULT_INTERVAL_MS = 30_000L
        private const val EXTRA_INTERVAL_SECONDS = "intervalSeconds"
        private const val EXTRA_ROOT_MODE = "rootMode"

        fun start(context: Context, intervalSeconds: Int, rootMode: Boolean) {
            val intent = Intent(context, KeepAliveService::class.java)
                .putExtra(EXTRA_INTERVAL_SECONDS, intervalSeconds)
                .putExtra(EXTRA_ROOT_MODE, rootMode)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, KeepAliveService::class.java))
        }
    }
}
