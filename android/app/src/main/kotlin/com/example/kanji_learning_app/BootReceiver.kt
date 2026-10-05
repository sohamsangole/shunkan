package com.example.kanji_learning_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val action = intent?.action
        if (action == Intent.ACTION_BOOT_COMPLETED || action == "android.intent.action.QUICKBOOT_POWERON") {
            val ctx = context ?: return
            val prefs = ctx.getSharedPreferences("kanji_lockscreen_prefs", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("service_enabled", true)
            if (isEnabled) {
                val serviceIntent = Intent(ctx, LockscreenKanjiService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    ctx.startForegroundService(serviceIntent)
                } else {
                    ctx.startService(serviceIntent)
                }
            }
        }
    }
}
