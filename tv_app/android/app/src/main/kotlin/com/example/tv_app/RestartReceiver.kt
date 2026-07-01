package com.example.tv_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class RestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AppLauncher.launch(context, preferRoot = true)
    }
}
