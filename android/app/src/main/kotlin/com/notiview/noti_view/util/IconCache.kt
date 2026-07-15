package com.notiview.noti_view.util

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.File
import java.io.FileOutputStream

/**
 * Resolves app label/icon at capture time and caches both, since the
 * source app may later be uninstalled and become unresolvable.
 */
object IconCache {
    private val labelCache = HashMap<String, String>()

    fun resolveAppLabel(context: Context, packageName: String): String {
        labelCache[packageName]?.let { return it }
        val pm = context.packageManager
        val label = try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        } catch (e: Exception) {
            packageName
        }
        labelCache[packageName] = label
        return label
    }

    fun cacheIcon(context: Context, packageName: String): String? {
        val dir = File(context.filesDir, "notif_icons")
        if (!dir.exists()) dir.mkdirs()
        val file = File(dir, "$packageName.png")
        if (file.exists() && file.length() > 0) return file.absolutePath
        return try {
            val drawable: Drawable = context.packageManager.getApplicationIcon(packageName)
            val bitmap = drawableToBitmap(drawable)
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            file.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 108
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 108
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
