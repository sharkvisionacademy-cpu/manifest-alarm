package com.sharkvision.manifestalarm

import android.Manifest
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import com.sharkvision.manifestalarm.Prefs.manifestText
import com.sharkvision.manifestalarm.databinding.ActivityAlarmBinding
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AlarmActivity : AppCompatActivity() {

    private lateinit var binding: ActivityAlarmBinding
    private var recognizer: SpeechRecognizer? = null
    private val handler = Handler(Looper.getMainLooper())
    private var listening = false
    private var dismissed = false
    private var failCount = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAlarmBinding.inflate(layoutInflater)
        setContentView(binding.root)
        showOverLockscreen()

        val manifest = manifestText
        binding.tvManifest.text = manifest
        binding.tvClock.text = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())

        binding.btnSpeak.setOnClickListener { beginListening() }

        binding.btnTypeConfirm.setOnClickListener {
            val typed = binding.etTyped.text?.toString() ?: ""
            if (SpeechMatcher.similarity(manifest, typed) >= 0.9) {
                onSuccess()
            } else {
                binding.tvStatus.text = getString(R.string.typed_wrong)
            }
        }

        // Mikrofon izni yoksa sesli yol çalışmaz; yazma yolunu göster
        if (!hasMicPermission() || !SpeechRecognizer.isRecognitionAvailable(this)) {
            showTypingFallback()
        }
    }

    private fun showOverLockscreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        (getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager)
            .requestDismissKeyguard(this, null)
    }

    private fun hasMicPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    private fun beginListening() {
        if (listening || dismissed) return
        listening = true
        sendServiceAction(AlarmService.ACTION_QUIET)
        binding.btnSpeak.isEnabled = false
        binding.tvStatus.text = getString(R.string.listening)

        if (recognizer == null) {
            recognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
                setRecognitionListener(listener)
            }
        }
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault().toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
        }
        recognizer?.startListening(intent)
    }

    private val listener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            binding.tvStatus.text = getString(R.string.speak_now)
        }

        override fun onPartialResults(partialResults: Bundle?) {
            val texts = partialResults
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION) ?: return
            texts.firstOrNull()?.takeIf { it.isNotBlank() }?.let {
                binding.tvHeard.text = it
            }
        }

        override fun onResults(results: Bundle?) {
            listening = false
            binding.btnSpeak.isEnabled = true
            val texts = results
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION).orEmpty()
            val manifest = manifestText
            val best = texts.maxOfOrNull { SpeechMatcher.similarity(manifest, it) } ?: 0.0
            texts.firstOrNull()?.let { binding.tvHeard.text = it }

            if (best >= SpeechMatcher.THRESHOLD) {
                onSuccess()
            } else {
                onFail(best)
            }
        }

        override fun onError(error: Int) {
            listening = false
            binding.btnSpeak.isEnabled = true
            when (error) {
                SpeechRecognizer.ERROR_NO_MATCH,
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                    binding.tvStatus.text = getString(R.string.not_heard)
                }
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> showTypingFallback()
                else -> {
                    binding.tvStatus.text = getString(R.string.recognition_error)
                    failCount++
                    if (failCount >= 3) showTypingFallback()
                }
            }
        }

        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {
            binding.tvStatus.text = getString(R.string.checking)
        }
        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun onFail(similarity: Double) {
        failCount++
        val percent = (similarity * 100).toInt()
        binding.tvStatus.text = getString(R.string.try_again_percent, percent)
        if (failCount >= 5) showTypingFallback()
    }

    private fun onSuccess() {
        if (dismissed) return
        dismissed = true
        sendServiceAction(AlarmService.ACTION_STOP)
        recognizer?.destroy()
        recognizer = null
        binding.tvStatus.text = getString(R.string.success)
        binding.tvHeard.text = ""
        binding.btnSpeak.isVisible = false
        binding.groupTyping.isVisible = false
        handler.postDelayed({ finish() }, 2000)
    }

    private fun showTypingFallback() {
        binding.groupTyping.isVisible = true
    }

    private fun sendServiceAction(action: String) {
        startService(Intent(this, AlarmService::class.java).setAction(action))
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Manifest söylenmeden alarm kapanmaz
    }

    override fun onDestroy() {
        recognizer?.destroy()
        recognizer = null
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
