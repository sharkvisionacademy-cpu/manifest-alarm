import Foundation
import UserNotifications

/// Gün içi manifest hatırlatıcılarını (öğlen / gün içi / uyku) yerel bildirimlerle yönetir.
/// Ücretsiz özellik — premium gerektirmez.
enum ReminderManager {
    // Ayar anahtarları (dakika = gece yarısından itibaren dakika)
    static let noon  = Reminder(id: "noon",  onKey: "remNoonOn",  minKey: "remNoonMin",  defaultMin: 13 * 60)
    static let day   = Reminder(id: "day",   onKey: "remDayOn",   minKey: "remDayMin",   defaultMin: 16 * 60)
    static let sleep = Reminder(id: "sleep", onKey: "remSleepOn", minKey: "remSleepMin", defaultMin: 22 * 60 + 30)
    static let all = [noon, day, sleep]

    struct Reminder {
        let id: String
        let onKey: String
        let minKey: String
        let defaultMin: Int
    }

    /// Herhangi bir hatırlatıcı açıksa bildirim izni ister.
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Tüm hatırlatıcıları yeniden zamanlar (önümüzdeki 7 gün, her gün farklı manifest).
    static func reschedule() {
        let center = UNUserNotificationCenter.current()
        let defaults = UserDefaults.standard
        let cal = Calendar.current

        // Önce eski hatırlatıcı bildirimlerini temizle.
        var ids: [String] = []
        for r in all { for offset in 0..<7 { ids.append("rem_\(r.id)_\(offset)") } }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for r in all where defaults.bool(forKey: r.onKey) {
            let minutes = defaults.object(forKey: r.minKey) == nil
                ? r.defaultMin
                : defaults.integer(forKey: r.minKey)
            for offset in 0..<7 {
                guard let dayDate = cal.date(byAdding: .day, value: offset, to: Date()) else { continue }
                var comps = cal.dateComponents([.year, .month, .day], from: dayDate)
                comps.hour = minutes / 60
                comps.minute = minutes % 60
                guard let fire = cal.date(from: comps), fire > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("reminder_title", comment: "")
                content.body = ManifestProvider.manifest(for: fire)
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
                    repeats: false
                )
                let req = UNNotificationRequest(
                    identifier: "rem_\(r.id)_\(offset)",
                    content: content,
                    trigger: trigger
                )
                center.add(req)
            }
        }
    }
}
