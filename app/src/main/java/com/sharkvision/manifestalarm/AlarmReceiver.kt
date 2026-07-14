package com.sharkvision.manifestalarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Alarm çaldı: servisi başlat, ertesi gün için yeniden kur
        ContextCompat.startForegroundService(
            context,
            Intent(context, AlarmService::class.java).setAction(AlarmService.ACTION_START)
        )
        AlarmScheduler.scheduleNext(context)
    }
}
