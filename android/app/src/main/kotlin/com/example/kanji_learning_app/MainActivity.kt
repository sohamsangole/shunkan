package com.example.kanji_learning_app

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.kanji_learning_app/lockscreen"
    private var methodChannel: MethodChannel? = null
    private var pendingKanjiId: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        var id = intent?.getStringExtra("kanji_id")
        if (id.isNullOrEmpty() && intent?.data != null) {
            id = intent.data?.lastPathSegment
        }
        android.util.Log.i("KanjiApp", "handleIntent called with action=${intent?.action}, id=$id")
        if (!id.isNullOrEmpty()) {
            pendingKanjiId = id
            methodChannel?.invokeMethod("onOpenKanji", id)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingKanji" -> {
                    val id = pendingKanjiId
                    pendingKanjiId = null
                    result.success(id)
                }
                "startLockscreenService" -> {
                    val prefs = getSharedPreferences(LockscreenKanjiService.PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit().putBoolean(LockscreenKanjiService.KEY_SERVICE_ENABLED, true).apply()

                    val intent = Intent(this, LockscreenKanjiService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopLockscreenService" -> {
                    val prefs = getSharedPreferences(LockscreenKanjiService.PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit().putBoolean(LockscreenKanjiService.KEY_SERVICE_ENABLED, false).apply()

                    val intent = Intent(this, LockscreenKanjiService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "updateKanjiPool" -> {
                    val jsonString = call.argument<String>("kanjiJson")
                    val prefs = getSharedPreferences(LockscreenKanjiService.PREFS_NAME, Context.MODE_PRIVATE)

                    // Fix #4: prune stale glance count entries — keep only IDs present in the new pool
                    try {
                        val newPool = org.json.JSONArray(jsonString ?: "[]")
                        val validIds = (0 until newPool.length())
                            .map { newPool.getJSONObject(it).optString("id", "") }
                            .toSet()
                        val glanceJson = org.json.JSONObject(
                            prefs.getString(LockscreenKanjiService.KEY_GLANCE_COUNTS, "{}") ?: "{}"
                        )
                        val staleKeys = (0 until glanceJson.length())
                            .mapNotNull { glanceJson.keys().asSequence().elementAtOrNull(it) }
                            .filter { it !in validIds }
                        staleKeys.forEach { glanceJson.remove(it) }
                        prefs.edit()
                            .putString(LockscreenKanjiService.KEY_KANJI_JSON, jsonString)
                            .putString(LockscreenKanjiService.KEY_GLANCE_COUNTS, glanceJson.toString())
                            .remove(LockscreenKanjiService.KEY_DECK_JSON)  // invalidate deck
                            .apply()
                    } catch (_: Exception) {
                        prefs.edit()
                            .putString(LockscreenKanjiService.KEY_KANJI_JSON, jsonString)
                            .remove(LockscreenKanjiService.KEY_DECK_JSON)
                            .apply()
                    }

                    val refreshImmediate = call.argument<Boolean>("refreshImmediate") ?: false
                    if (refreshImmediate && LockscreenKanjiService.isRunning) {
                        val intent = Intent(this, LockscreenKanjiService::class.java).apply {
                            action = LockscreenKanjiService.ACTION_REFRESH
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                    }
                    result.success(true)
                }

                // Fix #8: called by Flutter on JLPT level change — resets glance counts so
                // all kanji in the new level's pool start as Tier A (never seen on lockscreen)
                "resetGlanceCounts" -> {
                    val prefs = getSharedPreferences(LockscreenKanjiService.PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit()
                        .remove(LockscreenKanjiService.KEY_GLANCE_COUNTS)
                        .remove(LockscreenKanjiService.KEY_DECK_JSON)
                        .apply()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(LockscreenKanjiService.isRunning)
                }
                "getTelemetry" -> {
                    val prefs = getSharedPreferences(LockscreenKanjiService.PREFS_NAME, Context.MODE_PRIVATE)
                    val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())
                    val savedDate = prefs.getString("telemetry_date", "") ?: ""
                    val glancesToday = if (savedDate == today) prefs.getInt("telemetry_glances_today", 0) else 0
                    val kanjiSet = if (savedDate == today) (prefs.getStringSet("telemetry_kanji_today", null) ?: emptySet()) else emptySet()
                    val streak = prefs.getInt("telemetry_streak", 1)
                    val lastKanji = prefs.getString("telemetry_last_kanji", "") ?: ""
                    val lastMeaning = prefs.getString("telemetry_last_meaning", "") ?: ""

                    val map = HashMap<String, Any>()
                    map["glancesToday"] = glancesToday
                    map["uniqueKanjiToday"] = kanjiSet.size
                    map["streakDays"] = streak
                    map["lastKanji"] = lastKanji
                    map["lastMeaning"] = lastMeaning
                    result.success(map)
                }
                else -> result.notImplemented()
            }
        }
    }
}
