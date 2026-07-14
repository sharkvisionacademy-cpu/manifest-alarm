package com.sharkvision.manifestalarm

import java.util.Locale
import kotlin.math.max
import kotlin.math.min

/**
 * Söylenen cümle ile hedef manifest cümlesini karşılaştırır.
 * Sabah sesi kısık ve tanıma kusurlu olabileceği için tolerans payı vardır.
 */
object SpeechMatcher {

    const val THRESHOLD = 0.72

    fun normalize(s: String): String =
        s.lowercase(Locale.getDefault())
            .replace(Regex("[^\\p{L}\\p{Nd} ]"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()

    /** 0.0 – 1.0 arası benzerlik puanı. */
    fun similarity(expected: String, spoken: String): Double {
        val e = normalize(expected)
        val s = normalize(spoken)
        if (e.isEmpty()) return 1.0
        if (s.isEmpty()) return 0.0

        // Tüm cümle üzerinden karakter benzerliği
        val charSim = 1.0 - levenshtein(e, s).toDouble() / max(e.length, s.length)

        // Manifest kelimelerinin ne kadarı söylenmiş (kelime bazlı, hafif toleranslı)
        val eTokens = e.split(" ")
        val sTokens = s.split(" ")
        val covered = eTokens.count { t ->
            sTokens.any { tokenSimilarity(it, t) >= 0.8 }
        }
        val coverage = covered.toDouble() / eTokens.size

        return max(charSim, coverage)
    }

    fun matches(expected: String, spoken: String): Boolean =
        similarity(expected, spoken) >= THRESHOLD

    private fun tokenSimilarity(a: String, b: String): Double {
        if (a == b) return 1.0
        val maxLen = max(a.length, b.length)
        if (maxLen == 0) return 1.0
        return 1.0 - levenshtein(a, b).toDouble() / maxLen
    }

    private fun levenshtein(a: String, b: String): Int {
        if (a == b) return 0
        if (a.isEmpty()) return b.length
        if (b.isEmpty()) return a.length
        var prev = IntArray(b.length + 1) { it }
        var curr = IntArray(b.length + 1)
        for (i in 1..a.length) {
            curr[0] = i
            for (j in 1..b.length) {
                val cost = if (a[i - 1] == b[j - 1]) 0 else 1
                curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost)
            }
            val tmp = prev; prev = curr; curr = tmp
        }
        return prev[b.length]
    }
}
