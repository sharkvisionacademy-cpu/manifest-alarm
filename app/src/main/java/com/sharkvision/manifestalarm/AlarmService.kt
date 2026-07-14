package com.sharkvision.manifestalarm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.NotificationCompat

/**
 * Alarm sesini çalan ön plan servisi. Kilitli ekranda AlarmActivity'yi
 * tam ekran bildirimle açar. Konuşma tanıma sırasında sesi geçici susturur.
 */
class AlarmService : Service() {

    companion object {
        const val ACTION_START = "com.sharkvision.manifestalarm.START"
        const val ACTION_QUIET = "com.sharkvision.manifestalarm.QUIET"
        const val ACTION_RESUME = "com.sharkvision.manifestalarm.RESUME"
        const val ACTION_STOP = "com.sharkvision.manifestalarm.STOP"
        const val CHANNEL_ID = "manifest_alarm_channel"
        const val NOTIFICATION_ID = 42

        // Dinleme sırasında ses bu kadar ms sustuktan sonra kendiliğinden geri gelir
        private const val QUIET_TIMEOUT_MS = 25_000L
    }

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val handler = Handler(Looper.getMainLooper())
    private val resumeRunnable = Runnable { startSound() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_QUIET -> {
                stopSound()
                handler.removeCallbacks(resumeRunnable)
                handler.postDelayed(resumeRunnable, QUIET_TIMEOUT_MS)
            }
            ACTION_RESUME -> {
                handler.removeCallbacks(resumeRunnable)
                startSound()
            }
            ACTION_STOP -> {
                handler.removeCallbacks(resumeRunnable)
                stopSound()
                stopSelf()
            }
            else -> {
                createChannel()
                startAsForeground()
                startSound()
            }
        }
        return START_NOT_STICKY
    }

    private fun startAsForeground() {
        val fullScreenIntent = Intent(this, AlarmActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val fullScreenPi = PendingIntent.getActivity(
            this, 1, fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(getString(R.string.alarm_notification_title))
            .setContentText(getString(R.string.alarm_notification_text))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setFullScreenIntent(fullScreenPi, true)
            .setContentIntent(fullScreenPi)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun startSound() {
        if (player?.isPlaying == true) return
        if (player == null) {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            player = MediaPlayer().apply {
                setDataSource(this@AlarmService, uri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
            }
        }
        player?.start()
        startVibration()
    }

    private fun stopSound() {
        player?.takeIf { it.isPlaying }?.pause()
        vibrator?.cancel()
    }

    private fun startVibration() {
        if (vibrator == null) {
            @Suppress("DEPRECATION")
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
        val pattern = longArrayOf(0, 700, 500)
        vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
    }

    private fun createChannel() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.alarm_channel_name),
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = getString(R.string.alarm_channel_desc)
            setSound(null, null) // sesi servis kendisi çalar
            enableVibration(false)
        }
        nm.createNotificationChannel(channel)
    }

    override fun onDestroy() {
        handler.removeCallbacks(resumeRunnable)
        player?.release()
        player = null
        vibrator?.cancel()
        super.onDestroy()
    }
}
