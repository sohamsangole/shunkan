package com.example.kanji_learning_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.text.Html
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject        // Fix #3: explicit import
import java.util.Random

class LockscreenKanjiService : Service() {

    companion object {
        const val CHANNEL_ID         = "kanji_lock_screen_v2"
        const val CHANNEL_NAME       = "Shunkan Passive Kanji"
        const val NOTIFICATION_ID    = 1001
        const val ACTION_REFRESH     = "com.example.kanji_learning_app.ACTION_REFRESH"
        const val PREFS_NAME         = "kanji_lockscreen_prefs"
        const val KEY_KANJI_JSON     = "kanji_pool_json"
        const val KEY_SERVICE_ENABLED = "service_enabled"
        const val KEY_DECK_JSON      = "shuffle_deck_v2"   // stores kanji IDs now (v2)
        const val KEY_GLANCE_COUNTS  = "kanji_glance_counts"
        const val KEY_WINDOW_START_MS   = "window_start_ms"
        const val KEY_WINDOW_SEEN_KANJI = "window_seen_kanji"
        const val KEY_CYCLES_COMPLETED  = "cycles_completed"

        var isRunning = false
            private set
    }

    private val random = Random()
    private var receiverRegistered = false

    // Fix #6: guard so startForeground is only called once per service lifecycle
    private var foregroundStarted = false
    private var hasShownNotification = false
    private var lastScreenOffMs = 0L

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                val now = System.currentTimeMillis()
                if (now - lastScreenOffMs >= 2000L) {
                    lastScreenOffMs = now
                    showNextKanjiNotification(isInitial = false)
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        foregroundStarted = false
        hasShownNotification = false
        createNotificationChannel()
        ensureForeground()
        registerScreenReceiver()
    }

    private fun ensureForeground() {
        if (!foregroundStarted) {
            val placeholder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification_haru)
                .setContentTitle("Shunkan Passive Kanji")
                .setContentText("Preloading lock screen Kanji...")
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .build()

            if (Build.VERSION.SDK_INT >= 34) {
                try {
                    startForeground(NOTIFICATION_ID, placeholder, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
                } catch (_: Throwable) {
                    startForeground(NOTIFICATION_ID, placeholder)
                }
            } else {
                startForeground(NOTIFICATION_ID, placeholder)
            }
            foregroundStarted = true
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureForeground()
        val isRefresh = intent?.action == ACTION_REFRESH
        if (!hasShownNotification || isRefresh) {
            showNextKanjiNotification(isInitial = !isRefresh)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        unregisterScreenReceiver()
        isRunning = false
        foregroundStarted = false
        hasShownNotification = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        try {
            val manager = NotificationManagerCompat.from(this)
            manager.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun registerScreenReceiver() {
        if (!receiverRegistered) {
            val filter = IntentFilter().apply { addAction(Intent.ACTION_SCREEN_OFF) }
            registerReceiver(screenReceiver, filter)
            receiverRegistered = true
        }
    }

    private fun unregisterScreenReceiver() {
        if (receiverRegistered) {
            try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
            receiverRegistered = false
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows Kanji review flashcards on lock screen"
                setShowBadge(false)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                setSound(null, null)
                enableVibration(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    // -------------------------------------------------------------------------

    private fun showNextKanjiNotification(isInitial: Boolean) {
        val prefs  = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonStr = prefs.getString(KEY_KANJI_JSON, null) ?: return

        try {
            val array = JSONArray(jsonStr)
            val len   = array.length()
            if (len == 0) return

            // Fix #2: deck stores IDs → resolve to index at show time
            val kanjiId = popNextIdFromDeck(prefs, array)
            val idx = findIndexById(array, kanjiId)
            val item = array.getJSONObject(idx)

            val character      = item.optString("character", "日")
            val primaryMeaning = item.optString("primaryMeaning", "DAY")
            val meaningsDisplay = item.optString("meaningsDisplay", "")
            val onyomiDisplay  = item.optString("onyomiDisplay", "-")
            val kunyomiDisplay = item.optString("kunyomiDisplay", "-")

            // Increment lockscreen glance count (drives tier classification on next deck rebuild)
            try {
                val glanceJson = JSONObject(prefs.getString(KEY_GLANCE_COUNTS, "{}") ?: "{}")
                glanceJson.put(kanjiId, glanceJson.optInt(kanjiId, 0) + 1)
                prefs.edit().putString(KEY_GLANCE_COUNTS, glanceJson.toString()).apply()
            } catch (_: Exception) {}

            // Record passive telemetry — Fix #7: use kanjiId (not character) for uniqueness
            try {
                val today     = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())
                val savedDate = prefs.getString("telemetry_date", "") ?: ""
                var glancesToday = prefs.getInt("telemetry_glances_today", 0)
                var kanjiSet  = prefs.getStringSet("telemetry_kanji_today", null)?.toMutableSet() ?: mutableSetOf()
                var streak    = prefs.getInt("telemetry_streak", 1)

                val countsTodayJson = try {
                    if (savedDate == today) {
                        JSONObject(prefs.getString("telemetry_kanji_counts_today", "{}") ?: "{}")
                    } else {
                        JSONObject()
                    }
                } catch (_: Exception) {
                    JSONObject()
                }

                if (savedDate != today) {
                    val cal = java.util.Calendar.getInstance()
                    cal.add(java.util.Calendar.DATE, -1)
                    val yesterday = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(cal.time)
                    streak = when {
                        savedDate == yesterday -> streak + 1
                        savedDate.isNotEmpty() -> 1
                        else                   -> streak
                    }
                    glancesToday = 0
                    kanjiSet = mutableSetOf()
                }

                glancesToday += 1
                kanjiSet.add(kanjiId)   // Fix #7: was character, now kanjiId
                countsTodayJson.put(kanjiId, countsTodayJson.optInt(kanjiId, 0) + 1)

                val windowSeen = prefs.getStringSet(KEY_WINDOW_SEEN_KANJI, null)?.toMutableSet() ?: mutableSetOf()
                windowSeen.add(kanjiId)

                prefs.edit()
                    .putString("telemetry_date", today)
                    .putInt("telemetry_glances_today", glancesToday)
                    .putStringSet("telemetry_kanji_today", HashSet(kanjiSet))
                    .putString("telemetry_kanji_counts_today", countsTodayJson.toString())
                    .putStringSet(KEY_WINDOW_SEEN_KANJI, HashSet(windowSeen))
                    .putInt("telemetry_streak", streak)
                    .putString("telemetry_last_kanji", character)
                    .putString("telemetry_last_meaning", primaryMeaning)
                    .apply()
            } catch (_: Exception) {}

            // Format vocabulary examples (max 2 each)
            val onExamplesList  = buildExampleLines(item.optJSONArray("onExamples"))
            val kunExamplesList = buildExampleLines(item.optJSONArray("kunExamples"))

            // Collapsed view
            val collapsedView = RemoteViews(packageName, R.layout.notification_collapsed).apply {
                setTextViewText(R.id.noti_kanji_char, character)
                setTextViewText(R.id.noti_meaning, primaryMeaning.uppercase())
                setTextViewText(R.id.noti_on_reading, "ON: $onyomiDisplay")
                setTextViewText(R.id.noti_kun_reading, "KUN: $kunyomiDisplay")
            }

            // Expanded view
            val expandedView = RemoteViews(packageName, R.layout.notification_expanded).apply {
                setTextViewText(R.id.noti_kanji_char_large, character)
                setTextViewText(R.id.noti_primary_meaning_large, primaryMeaning.uppercase())
                setTextViewText(R.id.noti_meanings_full, "MEANING: ${meaningsDisplay.uppercase()}")

                val onSb = StringBuilder("<b>ON:</b> $onyomiDisplay")
                if (onExamplesList.isNotEmpty()) onSb.append("<br>").append(onExamplesList.joinToString("<br>"))
                setTextViewText(R.id.noti_on_section, Html.fromHtml(onSb.toString(), Html.FROM_HTML_MODE_LEGACY))

                val kunSb = StringBuilder("<b>KUN:</b> $kunyomiDisplay")
                if (kunExamplesList.isNotEmpty()) kunSb.append("<br>").append(kunExamplesList.joinToString("<br>"))
                setTextViewText(R.id.noti_kun_section, Html.fromHtml(kunSb.toString(), Html.FROM_HTML_MODE_LEGACY))
            }

            android.util.Log.i("LockscreenKanjiService", "Showing kanjiId=$kanjiId char=$character")

            val notifyIntent = Intent(this, MainActivity::class.java).apply {
                flags  = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                action = "com.example.kanji_learning_app.OPEN_KANJI"
                data   = android.net.Uri.parse("kanjiapp://open/$kanjiId")
                putExtra("kanji_id", kanjiId)
                putExtra("kanji_character", character)
            }
            val pendingIntent = PendingIntent.getActivity(
                this, NOTIFICATION_ID, notifyIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            collapsedView.setOnClickPendingIntent(R.id.noti_collapsed_root, pendingIntent)
            expandedView.setOnClickPendingIntent(R.id.noti_expanded_root, pendingIntent)

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification_haru)
                .setStyle(NotificationCompat.DecoratedCustomViewStyle())
                .setCustomContentView(collapsedView)
                .setCustomBigContentView(expandedView)
                .setCustomHeadsUpContentView(collapsedView)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setOnlyAlertOnce(true)
                .setOngoing(true)
                .setShowWhen(false)
                .setContentIntent(pendingIntent)
                .build()

            // Fix #6: startForeground only on the very first call per service lifecycle
            if (!foregroundStarted) {
                foregroundStarted = true
                if (Build.VERSION.SDK_INT >= 34) {
                    try {
                        startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
                    } catch (_: Throwable) {
                        startForeground(NOTIFICATION_ID, notification)
                    }
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else {
                val manager = NotificationManagerCompat.from(this)
                try { manager.notify(NOTIFICATION_ID, notification) } catch (_: SecurityException) {}
            }
            hasShownNotification = true

        } catch (_: Exception) {}
    }

    private fun buildExampleLines(arr: JSONArray?): List<String> {
        if (arr == null) return emptyList()
        val out = mutableListOf<String>()
        for (i in 0 until minOf(arr.length(), 2)) {
            val ex = arr.getJSONObject(i)
            val w  = ex.optString("word", "")
            val r  = ex.optString("reading", "")
            val m  = ex.optString("meaning", "")
            if (w.isNotEmpty()) out.add("• $w ($r) — $m")
        }
        return out
    }

    // -------------------------------------------------------------------------
    // Time-Windowed Catch-Up Shuffle Deck
    // -------------------------------------------------------------------------

    /**
     * Determines window duration dynamically based on pool size:
     * - N5 (<= 150):   1 Day  (24h)
     * - N4 (<= 450):   2 Days (48h)
     * - N3 (<= 850):   4 Days (96h)
     * - N2 (<= 1500):  7 Days (1 Week / 168h)
     * - N1 (> 1500):  14 Days (2 Weeks / 336h)
     */
    private fun getWindowDurationMs(poolSize: Int): Long {
        return when {
            poolSize <= 150  -> 1L * 24 * 3600 * 1000L   // N5: 1 Day
            poolSize <= 450  -> 2L * 24 * 3600 * 1000L   // N4: 2 Days
            poolSize <= 850  -> 4L * 24 * 3600 * 1000L   // N3: 4 Days
            poolSize <= 1500 -> 7L * 24 * 3600 * 1000L   // N2: 7 Days
            else             -> 14L * 24 * 3600 * 1000L  // N1: 14 Days
        }
    }

    /**
     * Pops the next kanji ID from the persisted shuffle deck.
     * Rebuilds a fresh deck when:
     * 1) Deck is empty (all cards popped), OR
     * 2) The level's time window has expired.
     */
    private fun popNextIdFromDeck(prefs: android.content.SharedPreferences, array: JSONArray): String {
        val poolSize = array.length()
        val windowDurationMs = getWindowDurationMs(poolSize)
        val windowStartMs = prefs.getLong(KEY_WINDOW_START_MS, 0L)
        val now = System.currentTimeMillis()
        val isWindowExpired = windowStartMs > 0L && (now - windowStartMs) >= windowDurationMs

        val deckStr = prefs.getString(KEY_DECK_JSON, null)
        val deck: ArrayDeque<String> = if (!deckStr.isNullOrEmpty()) {
            try {
                val arr = JSONArray(deckStr)
                ArrayDeque((0 until arr.length()).map { arr.getString(it) })
            } catch (_: Exception) { ArrayDeque() }
        } else ArrayDeque()

        if (deck.isEmpty() || isWindowExpired) {
            val isNewWindow = isWindowExpired || windowStartMs == 0L
            deck.clear()
            deck.addAll(buildWindowedDeck(prefs, array, poolSize, isNewWindow))
        }

        val chosen = if (deck.isNotEmpty()) deck.removeFirst()
                     else array.getJSONObject(0).optString("id", "0")

        // Persist remaining deck
        val remaining = JSONArray()
        deck.forEach { remaining.put(it) }
        prefs.edit().putString(KEY_DECK_JSON, remaining.toString()).apply()

        return chosen
    }

    /**
     * Looks up the array index for a given kanji ID.
     * Falls back to 0 if not found (e.g. stale deck entry after pool change).
     */
    private fun findIndexById(array: JSONArray, id: String): Int {
        for (i in 0 until array.length()) {
            if (array.getJSONObject(i).optString("id", "") == id) return i
        }
        return 0
    }

    /**
     * Builds a catch-up shuffle deck based on exposure:
     * - If isNewWindow: Evaluates previous window's coverage, resets window start to midnight,
     *   clears KEY_WINDOW_SEEN_KANJI for the new cycle, and increments cycle count.
     * - If NOT isNewWindow (intra-window refill): Preserves KEY_WINDOW_START_MS and
     *   KEY_WINDOW_SEEN_KANJI so coverage is NOT wiped if the deck empties before window expires.
     * - Kanji missed get 2 slots (catch-up priority) if coverage was >30%.
     * - Shuffled randomly with Fisher-Yates algorithm.
     */
    private fun buildWindowedDeck(
        prefs: android.content.SharedPreferences,
        array: JSONArray,
        poolSize: Int,
        isNewWindow: Boolean
    ): List<String> {
        val len = array.length()
        val deck = mutableListOf<String>()

        val seenInWindow = prefs.getStringSet(KEY_WINDOW_SEEN_KANJI, null) ?: emptySet()
        val isFirstRun = prefs.getLong(KEY_WINDOW_START_MS, 0L) == 0L
        val coveragePercent = if (len > 0) (seenInWindow.size.toDouble() / len.toDouble()) * 100.0 else 0.0

        var missedCount = 0
        var seenCount = 0

        // Threshold rule: If coverage was <= 30% (or first run), do not double missed cards.
        // Keep the deck strictly 1x (deck size = pool size) to avoid bloating on low activity.
        val shouldPrioritizeMissed = !isFirstRun && coveragePercent > 30.0 && len > 1

        for (i in 0 until len) {
            val item = array.getJSONObject(i)
            val id   = item.optString("id", "").ifEmpty { item.optString("character", "$i") }

            if (shouldPrioritizeMissed && !seenInWindow.contains(id)) {
                // Missed in previous/current window with active engagement (>30%): 2 slots (catch-up)
                deck.add(id)
                deck.add(id)
                missedCount++
            } else {
                // Seen, or engagement <= 30% (flat 1x deck): 1 slot
                deck.add(id)
                seenCount++
            }
        }

        // Fisher-Yates shuffle
        for (i in deck.indices.reversed()) {
            val j = random.nextInt(i + 1)
            val tmp = deck[i]; deck[i] = deck[j]; deck[j] = tmp
        }

        val editor = prefs.edit()
        if (isNewWindow) {
            val cal = java.util.Calendar.getInstance()
            cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
            cal.set(java.util.Calendar.MINUTE, 0)
            cal.set(java.util.Calendar.SECOND, 0)
            cal.set(java.util.Calendar.MILLISECOND, 0)
            val startOfDayMs = cal.timeInMillis

            editor.putLong(KEY_WINDOW_START_MS, startOfDayMs)
                .putStringSet(KEY_WINDOW_SEEN_KANJI, HashSet<String>())

            if (!isFirstRun) {
                val prevCycles = prefs.getInt(KEY_CYCLES_COMPLETED, 0)
                editor.putInt(KEY_CYCLES_COMPLETED, prevCycles + 1)
            }
        }
        editor.apply()

        val windowHours = getWindowDurationMs(poolSize) / (3600 * 1000L)
        val mode = if (isNewWindow) {
            if (shouldPrioritizeMissed) "new-window 2x catch-up" else "new-window flat 1x (coverage=${coveragePercent.toInt()}%)"
        } else {
            "intra-window refill (seen=${seenInWindow.size}/$len preserved)"
        }
        android.util.Log.i(
            "LockscreenKanjiService",
            "Window deck built ($mode): ${deck.size} slots from $len kanji ($missedCount missed [2x], $seenCount 1x, window=${windowHours}h)"
        )
        return deck
    }
}
