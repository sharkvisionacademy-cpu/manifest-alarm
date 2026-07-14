import Foundation

/// Söylenen cümle ile hedef manifest cümlesini karşılaştırır.
/// Sabah sesi kısık ve tanıma kusurlu olabileceği için tolerans payı vardır.
enum SpeechMatcher {

    static let threshold = 0.72

    static func normalize(_ s: String) -> String {
        let lowered = s.lowercased(with: Locale.current)
        let mapped = lowered.map { ch -> Character in
            (ch.isLetter || ch.isNumber) ? ch : " "
        }
        let collapsed = String(mapped)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed
    }

    /// 0.0 – 1.0 arası benzerlik puanı.
    static func similarity(expected: String, spoken: String) -> Double {
        let e = normalize(expected)
        let s = normalize(spoken)
        if e.isEmpty { return 1.0 }
        if s.isEmpty { return 0.0 }

        // Tüm cümle üzerinden karakter benzerliği
        let charSim = 1.0 - Double(levenshtein(e, s)) / Double(max(e.count, s.count))

        // Manifest kelimelerinin ne kadarı söylenmiş (kelime bazlı, hafif toleranslı)
        let eTokens = e.split(separator: " ").map(String.init)
        let sTokens = s.split(separator: " ").map(String.init)
        let covered = eTokens.filter { t in
            sTokens.contains { tokenSimilarity($0, t) >= 0.8 }
        }.count
        let coverage = Double(covered) / Double(eTokens.count)

        return max(charSim, coverage)
    }

    private static func tokenSimilarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1.0 }
        let maxLen = max(a.count, b.count)
        if maxLen == 0 { return 1.0 }
        return 1.0 - Double(levenshtein(a, b)) / Double(maxLen)
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        let aChars = Array(a), bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }
        var prev = Array(0...bChars.count)
        var curr = [Int](repeating: 0, count: bChars.count + 1)
        for i in 1...aChars.count {
            curr[0] = i
            for j in 1...bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                curr[j] = Swift.min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &curr)
        }
        return prev[bChars.count]
    }
}
