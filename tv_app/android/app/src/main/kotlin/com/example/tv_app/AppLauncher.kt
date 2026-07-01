package com.example.tv_app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object AppLauncher {
    private const val TAG = "AppLauncher"
    private const val RESTART_REQUEST_CODE = 1001

    fun launch(context: Context, preferRoot: Boolean = false): Boolean {
        if (preferRoot && RootTools.launchApp(context)) {
            return true
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)

        if (launchIntent == null) {
            Log.w(TAG, "Launch intent not found")
            return false
        }

        launchIntent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        )

        try {
            context.startActivity(launchIntent)
            return true
        } catch (error: Exception) {
            Log.e(TAG, "Unable to launch app", error)
            return false
        }
    }

    fun restartPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, RestartReceiver::class.java)

        return PendingIntent.getBroadcast(
            context,
            RESTART_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        )
    }

    private fun immutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }
}
