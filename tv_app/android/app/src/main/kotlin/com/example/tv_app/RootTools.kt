package com.example.tv_app

import android.content.Context
import android.util.Log
import java.util.concurrent.TimeUnit

object RootTools {
    private const val TAG = "RootTools"

    fun isRootAvailable(): Boolean {
        val result = runRootCommand("id", timeoutSeconds = 3)

        return result.success && result.output.contains("uid=0")
    }

    fun launchApp(context: Context): Boolean {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val component = launchIntent?.component?.flattenToShortString() ?: return false

        return runRootCommand("am start -n $component", timeoutSeconds = 5).success
    }

    fun applyKioskPolicy(context: Context) {
        val packageName = context.packageName

        runRootCommand(
            "settings put global policy_control immersive.full=$packageName",
            timeoutSeconds = 3,
        )
        runRootCommand("settings put system screen_off_timeout 2147483647", timeoutSeconds = 3)
        runRootCommand("svc power stayon true", timeoutSeconds = 3)
    }

    private fun runRootCommand(command: String, timeoutSeconds: Long): RootCommandResult {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
            val completed = process.waitFor(timeoutSeconds, TimeUnit.SECONDS)

            if (!completed) {
                process.destroyForcibly()
                return RootCommandResult(success = false, output = "")
            }

            val output = process.inputStream.bufferedReader().readText() +
                process.errorStream.bufferedReader().readText()

            RootCommandResult(success = process.exitValue() == 0, output = output)
        } catch (error: Exception) {
            Log.d(TAG, "Root command failed: $command", error)
            RootCommandResult(success = false, output = "")
        }
    }

    private data class RootCommandResult(
        val success: Boolean,
        val output: String,
    )
}
