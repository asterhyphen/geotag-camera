package com.example.geocam

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanFile") {
                    val path = call.argument<String>("path")
                    MediaScannerConnection.scanFile(
                        this,
                        arrayOf(path),
                        null,
                        null
                    )
                    result.success(null)
                }
            }
    }
}
