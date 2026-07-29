import Foundation

/// Manifestini söyleyerek alarmı kapattığın gün sayısını (seriyi) takip eder.
/// currentStreak: kesintisiz gün, bestStreak: en uzun seri.
enum StreakTracker {
    private static let d = UserDefaults.standard

    private static var formatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }

    static var best: Int { d.integer(forKey: "streakBest") }

    /// Seri kopmuşsa (son tamamlamadan bu yana 1 günden fazla geçtiyse) 0 döner.
    static var displayCurrent: Int {
        guard let lastStr = d.string(forKey: "streakLastDate"),
              let last = formatter.date(from: lastStr) else { return 0 }
        let cal = Calendar.current
        let diff = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: last),
            to: cal.startOfDay(for: Date())
        ).day ?? 99
        return diff <= 1 ? d.integer(forKey: "streakCurrent") : 0
    }

    /// Manifest başarıyla söylenince çağrılır; günlük seriyi günceller.
    static func recordCompletion(now: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let todayStr = formatter.string(from: today)

        // Bugün zaten sayıldıysa tekrar artırma.
        if d.string(forKey: "streakLastDate") == todayStr { return }

        var streak = 1
        if let lastStr = d.string(forKey: "streakLastDate"),
           let last = formatter.date(from: lastStr) {
            let diff = cal.dateComponents(
                [.day],
                from: cal.startOfDay(for: last),
                to: today
            ).day ?? 99
            streak = (diff == 1) ? d.integer(forKey: "streakCurrent") + 1 : 1
        }

        d.set(streak, forKey: "streakCurrent")
        d.set(todayStr, forKey: "streakLastDate")
        if streak > d.integer(forKey: "streakBest") {
            d.set(streak, forKey: "streakBest")
        }
    }
}
