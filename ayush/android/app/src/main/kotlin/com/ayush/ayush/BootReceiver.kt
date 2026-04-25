package com.ayush.ayush

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.d("BootReceiver", "Boot completed — checking fall detection state")

            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )

            // SharedPreferences keys from flutter use "flutter." prefix
            val enabled = prefs.getBoolean("flutter.fall_detection_enabled", false)
            Log.d("BootReceiver", "Fall detection enabled: $enabled")

            if (enabled) {
                Log.d("BootReceiver", "Restarting AYUSH fall detection service...")
                // Start the Flutter background service via an explicit service intent
                val serviceIntent = Intent(context, Class.forName(
                    "id.flutter.flutter_background_service.BackgroundService"
                ))
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
