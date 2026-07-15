package com.notiview.noti_view.service

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.content.ContextCompat
import com.notiview.noti_view.db.NotiDatabase
import com.notiview.noti_view.util.IconCache
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

class NotiListenerService : NotificationListenerService() {

    private lateinit var db: NotiDatabase

    override fun onCreate() {
        super.onCreate()
        db = NotiDatabase.getInstance(applicationContext)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "Listener connected")
        // Ensure the reliability foreground service is running whenever the
        // system (re)binds this listener, e.g. after boot or an OS-triggered restart.
        ContextCompat.startForegroundService(this, Intent(this, NotiForegroundService::class.java))
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            capture(sbn, isRemoval = false, removalReason = null)
        } catch (e: Exception) {
            Log.e(TAG, "capture posted failed", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification, rankingMap: RankingMap?, reason: Int) {
        try {
            capture(sbn, isRemoval = true, removalReason = reason)
        } catch (e: Exception) {
            Log.e(TAG, "capture removed failed", e)
        }
    }

    private fun capture(sbn: StatusBarNotification, isRemoval: Boolean, removalReason: Int?) {
        val pkg = sbn.packageName
        // Skip our own reliability-service notification to avoid noise/self-capture loops.
        if (pkg == applicationContext.packageName) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: Bundle()
        val now = System.currentTimeMillis()

        val openChainId = db.findOpenChainId(sbn.key)
        val eventType: String
        val chainId: String
        if (isRemoval) {
            eventType = "REMOVED"
            chainId = openChainId ?: UUID.randomUUID().toString()
        } else if (openChainId != null) {
            eventType = "UPDATED"
            chainId = openChainId
        } else {
            eventType = "POSTED"
            chainId = UUID.randomUUID().toString()
        }

        val appLabel = IconCache.resolveAppLabel(applicationContext, pkg)
        // Don't bother caching an icon for a removal event; it was already
        // cached (or attempted) on the corresponding POSTED/UPDATED event.
        val iconPath = if (!isRemoval) IconCache.cacheIcon(applicationContext, pkg) else null

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
        val convTitle = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()

        db.insertEvent(
            chainId = chainId,
            notificationKey = sbn.key,
            groupKey = sbn.groupKey,
            packageName = pkg,
            appLabel = appLabel,
            eventType = eventType,
            deviceEventTime = now,
            sbnPostTime = sbn.postTime,
            title = title,
            body = body,
            bigText = bigText,
            subText = subText,
            conversationTitle = convTitle,
            messagingStyleJson = extractMessagingStyle(extras),
            iconPath = iconPath,
            isOngoing = (notification.flags and Notification.FLAG_ONGOING_EVENT) != 0,
            category = notification.category,
            removalReason = removalReason
        )
    }

    /**
     * EXTRA_MESSAGES bundles use undocumented-but-stable key names shared by the
     * framework and NotificationCompat ("text"/"time"/"sender"). This is a
     * best-effort heuristic, not a guaranteed API contract.
     */
    private fun extractMessagingStyle(extras: Bundle): String? {
        return try {
            val messagesArr = extras.getParcelableArray(Notification.EXTRA_MESSAGES) ?: return null
            val jsonArr = JSONArray()
            for (m in messagesArr) {
                val b = m as? Bundle ?: continue
                val obj = JSONObject()
                obj.put("text", b.getCharSequence("text")?.toString() ?: "")
                obj.put("time", b.getLong("time", 0L))
                obj.put("sender", b.getCharSequence("sender")?.toString() ?: "")
                jsonArr.put(obj)
            }
            jsonArr.toString()
        } catch (e: Exception) {
            null
        }
    }

    companion object {
        private const val TAG = "NotiListenerService"
    }
}
