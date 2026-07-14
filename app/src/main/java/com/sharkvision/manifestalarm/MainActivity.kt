package com.sharkvision.manifestalarm

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import com.sharkvision.manifestalarm.Prefs.alarmEnabled
import com.sharkvision.manifestalarm.Prefs.alarmHour
import com.sharkvision.manifestalarm.Prefs.alarmMinute
import com.sharkvision.manifestalarm.Prefs.manifestText
import com.sharkvision.manifestalarm.databinding.ActivityMainBinding
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    private val permissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.timePicker.setIs24HourView(true)
        binding.timePicker.hour = alarmHour
        binding.timePicker.minute = alarmMinute
        binding.etManifest.setText(manifestText)
        binding.switchAlarm.isChecked = alarmEnabled

        binding.timePicker.setOnTimeChangedListener { _, _, _ -> save() }
        binding.switchAlarm.setOnCheckedChangeListener { _, _ -> save() }
        binding.btnSave.setOnClickListener {
            save()
            updateNextAlarmText()
        }
        binding.btnTest.setOnClickListener {
            save()
            ContextCompat.startForegroundService(
                this,
                Intent(this, AlarmService::class.java).setAction(AlarmService.ACTION_START)
            )
        }
        binding.btnExactPermission.setOnClickListener {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM))
            }
        }

        requestNeededPermissions()
    }

    override fun onResume() {
        super.onResume()
        binding.btnExactPermission.isVisible = !AlarmScheduler.canScheduleExact(this)
        updateNextAlarmText()
    }

    private fun save() {
        alarmHour = binding.timePicker.hour
        alarmMinute = binding.timePicker.minute
        val text = binding.etManifest.text?.toString()?.trim().orEmpty()
        manifestText = text.ifEmpty { getString(R.string.default_manifest) }
        alarmEnabled = binding.switchAlarm.isChecked
        AlarmScheduler.scheduleNext(this)
        updateNextAlarmText()
    }

    private fun updateNextAlarmText() {
        if (alarmEnabled) {
            val next = AlarmScheduler.nextTriggerMillis(alarmHour, alarmMinute)
            val fmt = SimpleDateFormat("d MMMM EEEE HH:mm", Locale.getDefault())
            binding.tvNextAlarm.text = getString(R.string.next_alarm, fmt.format(Date(next)))
        } else {
            binding.tvNextAlarm.text = getString(R.string.alarm_off)
        }
    }

    private fun requestNeededPermissions() {
        val needed = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            needed += Manifest.permission.RECORD_AUDIO
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            needed += Manifest.permission.POST_NOTIFICATIONS
        }
        if (needed.isNotEmpty()) permissionLauncher.launch(needed.toTypedArray())
    }
}
