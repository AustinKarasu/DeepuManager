package com.deepumanager.app

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setBackgroundDrawable(ColorDrawable(Color.rgb(37, 99, 235)))
        window.statusBarColor = Color.rgb(37, 99, 235)
        window.navigationBarColor = Color.rgb(37, 99, 235)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "deepu_manager/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                val text = call.argument<String>("text") ?: "Deepu Manager file"
                if (path.isNullOrBlank()) {
                    result.error("missing_path", "File path is missing", null)
                    return@setMethodCallHandler
                }
                val file = File(path)
                if (!file.exists()) {
                    result.error("missing_file", "File does not exist", null)
                    return@setMethodCallHandler
                }
                val uri: Uri = FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file
                )
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = when (file.extension.lowercase()) {
                        "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                        "pdf" -> "application/pdf"
                        "csv" -> "text/csv"
                        else -> "application/octet-stream"
                    }
                    putExtra(Intent.EXTRA_STREAM, uri)
                    putExtra(Intent.EXTRA_TEXT, text)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(Intent.createChooser(intent, "Share Deepu Manager file"))
                result.success(null)
            }
    }
}
