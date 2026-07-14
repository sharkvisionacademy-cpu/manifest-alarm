package com.sharkvision.manifestalarm

import android.content.Context
import android.content.SharedPreferences

object Prefs {
    private const val NAME = "manifest_alarm_prefs"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    var Context.alarmHour: Int
        get() = prefs(this).getInt("hour", 8)
        set(v) = prefs(this).edit().putInt("hour", v).apply()

    var Context.alarmMinute: Int
        get() = prefs(this).getInt("minute", 0)
        set(v) = prefs(this).edit().putInt("minute", v).apply()

    var Context.alarmEnabled: Boolean
        get() = prefs(this).getBoolean("enabled", false)
        set(v) = prefs(this).edit().putBoolean("enabled", v).apply()

    var Context.manifestText: String
        get() = prefs(this).getString("manifest", null)
            ?: getString(R.string.default_manifest)
        set(v) = prefs(this).edit().putString("manifest", v).apply()
}
