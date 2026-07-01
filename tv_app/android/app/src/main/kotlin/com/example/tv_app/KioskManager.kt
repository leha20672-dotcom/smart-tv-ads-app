package com.example.tv_app

import android.app.Activity
import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.util.Log

object KioskManager {
    private const val TAG = "KioskManager"

    fun enter(activity: Activity, rootMode: Boolean) {
        keepScreenAwake(activity)
        hideSystemUi(activity)
        startLockTaskIfAllowed(activity)

        if (rootMode) {
            RootTools.applyKioskPolicy(activity.applicationContext)
        }
    }

    fun exit(activity: Activity) {
        try {
            activity.stopLockTask()
        } catch (error: Exception) {
            Log.d(TAG, "Unable to stop lock task", error)
        }
    }

    fun keepScreenAwake(activity: Activity) {
        activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    fun hideSystemUi(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.systemBars())
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
            return
        }

        @Suppress("DEPRECATION")
        activity.window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    }

    private fun startLockTaskIfAllowed(activity: Activity) {
        val context = activity.applicationContext
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val admin = ComponentName(context, KioskDeviceAdminReceiver::class.java)
        val packageName = context.packageName

        try {
            if (dpm.isDeviceOwnerApp(packageName)) {
                dpm.setLockTaskPackages(admin, arrayOf(packageName))
            }

            if (!dpm.isLockTaskPermitted(packageName)) {
                return
            }

            val activityManager =
                context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

            if (
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
            ) {
                return
            }

            activity.startLockTask()
        } catch (error: Exception) {
            Log.d(TAG, "Lock task is not available", error)
        }
    }
}
