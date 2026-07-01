package com.example.tv_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File
import java.util.concurrent.TimeUnit

object ApkInstaller {
    private const val TAG = "ApkInstaller"
    private const val APK_MIME_TYPE = "application/vnd.android.package-archive"

    fun install(context: Context, apkPath: String, preferRootInstall: Boolean): Boolean {
        val apkFile = File(apkPath)

        if (!apkFile.exists() || !apkFile.isFile) {
            throw IllegalArgumentException("APK file not found: $apkPath")
        }

        if (preferRootInstall && tryRootInstall(apkFile)) {
            return true
        }

        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !context.packageManager.canRequestPackageInstalls()
        ) {
            openInstallPermissionSettings(context)
            return false
        }

        openPackageInstaller(context, apkFile)
        return true
    }

    private fun tryRootInstall(apkFile: File): Boolean {
        return try {
            val command = "pm install -r ${shellQuote(apkFile.absolutePath)}"
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
            val completed = process.waitFor(90, TimeUnit.SECONDS)

            if (!completed) {
                process.destroyForcibly()
                return false
            }

            process.exitValue() == 0
        } catch (error: Exception) {
            Log.d(TAG, "Root install unavailable", error)
            false
        }
    }

    private fun openInstallPermissionSettings(context: Context) {
        val intent = Intent(
            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
            Uri.parse("package:${context.packageName}")
        )

        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun openPackageInstaller(context: Context, apkFile: File) {
        val apkUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                apkFile
            )
        } else {
            Uri.fromFile(apkFile)
        }

        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(apkUri, APK_MIME_TYPE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        context.startActivity(intent)
    }

    private fun shellQuote(value: String): String {
        return "'${value.replace("'", "'\\''")}'"
    }
}
