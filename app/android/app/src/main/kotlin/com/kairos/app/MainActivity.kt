package com.kairos.app

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Bridges the system notification-sound picker (RingtoneManager) to
/// Dart — Flutter has no built-in way to let the user pick from every
/// sound already on their device, and flutter_local_notifications'
/// UriAndroidNotificationSound just consumes whatever URI this returns.
class MainActivity : FlutterActivity() {
    private val channelName = "com.kairos.app/ringtone_picker"
    private val pickRequestCode = 4201
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "pickRingtone") {
                if (pendingResult != null) {
                    result.error("busy", "A ringtone picker request is already in progress", null)
                    return@setMethodCallHandler
                }
                val currentUri = call.argument<String>("currentUri")
                pendingResult = result
                val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                    putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
                    putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                    putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                    putExtra(
                        RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI,
                        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    )
                    if (currentUri != null) {
                        putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(currentUri))
                    }
                }
                startActivityForResult(intent, pickRequestCode)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode) return
        val result = pendingResult ?: return
        pendingResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        if (uri == null) {
            result.success(null)
            return
        }
        val ringtone = RingtoneManager.getRingtone(this, uri)
        val title = ringtone?.getTitle(this) ?: uri.toString()
        result.success(mapOf("uri" to uri.toString(), "title" to title))
    }
}
