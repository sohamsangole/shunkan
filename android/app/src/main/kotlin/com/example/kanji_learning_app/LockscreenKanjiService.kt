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

        var isRunning = false
            private set
    }

    private val random = Random()
    private var receiverRegistered = false

    // Fix #6: guard so startForeground is only called once per service lifecycle
    private var foregroundStarted = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                showNextKanjiNotification(isInitial = false)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        foregroundStarted = false
        createNotificationChannel()
        registerScreenReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val isRefresh = intent?.action == ACTION_REFRESH
        showNextKanjiNotification(isInitial = !isRefresh)
        return START_STICKY
    }

    override fun onDestroy() {
        unregisterScreenReceiver()
        isRunning = false
        foregroundStarted = false
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

                prefs.edit()
                    .putString("telemetry_date", today)
                    .putInt("telemetry_glances_today", glancesToday)
                    .putStringSet("telemetry_kanji_today", kanjiSet)
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
    // Stratified Shuffle Deck
    // -------------------------------------------------------------------------

    /**
     * Pops the next kanji ID from the persisted shuffle deck.
     * The deck is a list of kanji IDs (Fix #2: IDs not indices).
     * Rebuilt when empty using tier rules:
     *   Tier A — glances == 0  → 2 slots  (never shown on lockscreen)
     *   Tier B — glances >= 1  → 1 slot   (already encountered)
     * Fix #5: 2-slot behaviour skipped when pool has only 1 kanji.
     */
    private fun popNextIdFromDeck(prefs: android.content.SharedPreferences, array: JSONArray): String {
        val deckStr = prefs.getString(KEY_DECK_JSON, null)
        val deck: ArrayDeque<String> = if (!deckStr.isNullOrEmpty()) {
            try {
                val arr = JSONArray(deckStr)
                ArrayDeque((0 until arr.length()).map { arr.getString(it) })
            } catch (_: Exception) { ArrayDeque() }
        } else ArrayDeque()

        if (deck.isEmpty()) {
            deck.addAll(buildShuffledDeck(prefs, array))
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
     * Builds a fresh stratified deck of kanji IDs and Fisher-Yates shuffles it.
     * Fix #5: single-kanji pool gets exactly 1 slot to avoid back-to-back duplicates.
     */
    private fun buildShuffledDeck(prefs: android.content.SharedPreferences, array: JSONArray): List<String> {
        val len = array.length()
        val deck = mutableListOf<String>()

        val glanceJson = try {
            JSONObject(prefs.getString(KEY_GLANCE_COUNTS, "{}") ?: "{}")
        } catch (_: Exception) { JSONObject() }

        for (i in 0 until len) {
            val item    = array.getJSONObject(i)
            val id      = item.optString("id", "").ifEmpty { item.optString("character", "$i") }
            val glances = glanceJson.optInt(id, 0)

            if (glances == 0 && len > 1) {
                // Tier A: never shown, pool > 1 → 2 slots (Fix #5: skip if pool == 1)
                deck.add(id)
                deck.add(id)
            } else {
                // Tier B: seen at least once, OR only 1 kanji in pool → 1 slot
                deck.add(id)
            }
        }

        // Fisher-Yates shuffle
        for (i in deck.indices.reversed()) {
            val j = random.nextInt(i + 1)
            val tmp = deck[i]; deck[i] = deck[j]; deck[j] = tmp
        }

        val neverSeen = (0 until len).count { i ->
            val id = array.getJSONObject(i).optString("id", "").ifEmpty { "$i" }
            glanceJson.optInt(id, 0) == 0
        }
        android.util.Log.i(
            "LockscreenKanjiService",
            "Deck rebuilt: ${deck.size} slots from $len kanji ($neverSeen never seen)"
        )
        return deck
    }
}
