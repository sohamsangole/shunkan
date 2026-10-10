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
            val prefs = ctx.getSharedPreferences(LockscreenKanjiService.PREFS_NAME, Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean(LockscreenKanjiService.KEY_SERVICE_ENABLED, false)
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
