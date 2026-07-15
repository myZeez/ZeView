package com.notiview.noti_view.db

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * Append-only event log. Rows are never updated or overwritten so that
 * content captured for a notification (e.g. a WhatsApp message) survives
 * even if the source app later replaces/removes the notification.
 * WAL mode lets Flutter's sqflite read this file concurrently while this
 * service is the sole writer.
 */
class NotiDatabase private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DB_NAME, null, DB_VERSION) {

    private val db: SQLiteDatabase by lazy {
        val d = writableDatabase
        d.enableWriteAheadLogging()
        d
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(CREATE_TABLE_SQL)
        db.execSQL("CREATE INDEX idx_pkg_time ON $TABLE_NAME(package_name, device_event_time)")
        db.execSQL("CREATE INDEX idx_chain ON $TABLE_NAME(chain_id)")
        db.execSQL("CREATE INDEX idx_key ON $TABLE_NAME(notification_key)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_NAME")
        onCreate(db)
    }

    /** Finds the chain_id of the most recent non-REMOVED row for this notification key, if any. */
    @Synchronized
    fun findOpenChainId(notificationKey: String): String? {
        db.rawQuery(
            "SELECT chain_id FROM $TABLE_NAME WHERE notification_key = ? AND event_type != 'REMOVED' " +
                "ORDER BY event_id DESC LIMIT 1",
            arrayOf(notificationKey)
        ).use { cursor ->
            return if (cursor.moveToFirst()) cursor.getString(0) else null
        }
    }

    @Synchronized
    fun insertEvent(
        chainId: String,
        notificationKey: String?,
        groupKey: String?,
        packageName: String,
        appLabel: String,
        eventType: String,
        deviceEventTime: Long,
        sbnPostTime: Long,
        title: String?,
        body: String?,
        bigText: String?,
        subText: String?,
        conversationTitle: String?,
        messagingStyleJson: String?,
        iconPath: String?,
        isOngoing: Boolean,
        category: String?,
        removalReason: Int?
    ): Long {
        val values = ContentValues().apply {
            put("chain_id", chainId)
            put("notification_key", notificationKey)
            put("group_key", groupKey)
            put("package_name", packageName)
            put("app_label", appLabel)
            put("event_type", eventType)
            put("device_event_time", deviceEventTime)
            put("sbn_post_time", sbnPostTime)
            put("title", title)
            put("body", body)
            put("big_text", bigText)
            put("sub_text", subText)
            put("conversation_title", conversationTitle)
            put("messaging_style_json", messagingStyleJson)
            put("icon_path", iconPath)
            put("is_ongoing", if (isOngoing) 1 else 0)
            put("category", category)
            if (removalReason != null) put("removal_reason", removalReason)
        }
        return db.insert(TABLE_NAME, null, values)
    }

    companion object {
        private const val DB_NAME = "notiview_events.db"
        private const val DB_VERSION = 1
        const val TABLE_NAME = "notification_events"

        private const val CREATE_TABLE_SQL = """
            CREATE TABLE $TABLE_NAME (
                event_id INTEGER PRIMARY KEY AUTOINCREMENT,
                chain_id TEXT NOT NULL,
                notification_key TEXT,
                group_key TEXT,
                package_name TEXT NOT NULL,
                app_label TEXT,
                event_type TEXT NOT NULL,
                device_event_time INTEGER NOT NULL,
                sbn_post_time INTEGER,
                title TEXT,
                body TEXT,
                big_text TEXT,
                sub_text TEXT,
                conversation_title TEXT,
                messaging_style_json TEXT,
                icon_path TEXT,
                is_ongoing INTEGER,
                category TEXT,
                removal_reason INTEGER
            )
        """

        @Volatile private var instance: NotiDatabase? = null

        fun getInstance(context: Context): NotiDatabase =
            instance ?: synchronized(this) {
                instance ?: NotiDatabase(context).also { instance = it }
            }
    }
}
