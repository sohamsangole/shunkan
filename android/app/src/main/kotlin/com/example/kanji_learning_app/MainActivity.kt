package com.example.kanji_learning_app

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

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
            intent?.removeExtra("kanji_id")
            intent?.data = null

            val channel = methodChannel
            if (channel != null) {
                pendingKanjiId = null
                channel.invokeMethod("onOpenKanji", id)
            } else {
                pendingKanjiId = id
            }
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
                    val oldPoolJson = prefs.getString(LockscreenKanjiService.KEY_KANJI_JSON, null)

                    // Only reset deck and window if the pool actually changed (e.g. JLPT level switch)
                    if (oldPoolJson != jsonString) {
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

                            // Count cycle from the start of today (midnight 00:00:00)
                            val cal = java.util.Calendar.getInstance()
                            cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                            cal.set(java.util.Calendar.MINUTE, 0)
                            cal.set(java.util.Calendar.SECOND, 0)
                            cal.set(java.util.Calendar.MILLISECOND, 0)
                            val startOfDayMs = cal.timeInMillis

                            // Retain any kanji seen today that are part of the new pool
                            val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())
                            val savedDate = prefs.getString("telemetry_date", "") ?: ""
                            val todayKanjiSet = if (savedDate == today) (prefs.getStringSet("telemetry_kanji_today", null) ?: emptySet()) else emptySet()
                            val validSeenToday = todayKanjiSet.filter { it in validIds }.toSet()

                            prefs.edit()
                                .putString(LockscreenKanjiService.KEY_KANJI_JSON, jsonString)
                                .putString(LockscreenKanjiService.KEY_GLANCE_COUNTS, glanceJson.toString())
                                .remove(LockscreenKanjiService.KEY_DECK_JSON)  // invalidate deck for new pool
                                .putLong(LockscreenKanjiService.KEY_WINDOW_START_MS, startOfDayMs)
                                .putStringSet(LockscreenKanjiService.KEY_WINDOW_SEEN_KANJI, HashSet(validSeenToday))
                                .apply()
                        } catch (_: Exception) {
                            val cal = java.util.Calendar.getInstance()
                            cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                            cal.set(java.util.Calendar.MINUTE, 0)
                            cal.set(java.util.Calendar.SECOND, 0)
                            cal.set(java.util.Calendar.MILLISECOND, 0)

                            prefs.edit()
                                .putString(LockscreenKanjiService.KEY_KANJI_JSON, jsonString)
                                .remove(LockscreenKanjiService.KEY_DECK_JSON)
                                .putLong(LockscreenKanjiService.KEY_WINDOW_START_MS, cal.timeInMillis)
                                .remove(LockscreenKanjiService.KEY_WINDOW_SEEN_KANJI)
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
                        .remove(LockscreenKanjiService.KEY_WINDOW_START_MS)
                        .remove(LockscreenKanjiService.KEY_WINDOW_SEEN_KANJI)
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
                    val cal = java.util.Calendar.getInstance()
                    cal.add(java.util.Calendar.DATE, -1)
                    val yesterday = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(cal.time)
                    val isStreakActive = savedDate == today || savedDate == yesterday
                    val streak = if (isStreakActive) prefs.getInt("telemetry_streak", 1) else 0
                    val lastKanji = prefs.getString("telemetry_last_kanji", "") ?: ""
                    val lastMeaning = prefs.getString("telemetry_last_meaning", "") ?: ""
                    val countsTodayStr = if (savedDate == today) prefs.getString("telemetry_kanji_counts_today", "{}") ?: "{}" else "{}"
                    val countsMap = HashMap<String, Int>()
                    try {
                        val countsObj = JSONObject(countsTodayStr)
                        val keys = countsObj.keys()
                        while (keys.hasNext()) {
                            val k = keys.next()
                            countsMap[k] = countsObj.optInt(k, 1)
                        }
                    } catch (_: Exception) {}

                    val cycles = prefs.getInt(LockscreenKanjiService.KEY_CYCLES_COMPLETED, 0)
                    val windowStartMs = prefs.getLong(LockscreenKanjiService.KEY_WINDOW_START_MS, 0L)
                    val windowSeenSet = prefs.getStringSet(LockscreenKanjiService.KEY_WINDOW_SEEN_KANJI, null)?.toMutableSet() ?: mutableSetOf()

                    // Ensure any kanji seen today during this active cycle belonging to the active pool are included in windowSeenSet
                    val validPoolIds = try {
                        val poolStr = prefs.getString(LockscreenKanjiService.KEY_KANJI_JSON, "[]") ?: "[]"
                        val poolArr = org.json.JSONArray(poolStr)
                        (0 until poolArr.length()).map { poolArr.getJSONObject(it).optString("id", "") }.toSet()
                    } catch (_: Exception) { emptySet() }

                    val validKanjiToday = if (validPoolIds.isNotEmpty()) kanjiSet.filter { it in validPoolIds }.toSet() else kanjiSet
                    if (validKanjiToday.isNotEmpty() && !windowSeenSet.containsAll(validKanjiToday)) {
                        windowSeenSet.addAll(validKanjiToday)
                        prefs.edit().putStringSet(LockscreenKanjiService.KEY_WINDOW_SEEN_KANJI, HashSet(windowSeenSet)).apply()
                    }

                    val map = HashMap<String, Any>()
                    map["glancesToday"] = glancesToday
                    map["uniqueKanjiToday"] = kanjiSet.size
                    map["kanjiIdsToday"] = ArrayList(kanjiSet)
                    map["kanjiGlanceCountsToday"] = countsMap
                    map["streakDays"] = streak
                    map["cyclesCompleted"] = cycles
                    map["windowStartMs"] = windowStartMs
                    map["windowSeenCount"] = windowSeenSet.size
                    map["lastKanji"] = lastKanji
                    map["lastMeaning"] = lastMeaning
                    result.success(map)
                }
                else -> result.notImplemented()
            }
        }
    }
}
