import Foundation
import SwiftUI

// MARK: - Alarm modeli

struct AlarmItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var enabled: Bool = true

    var timeText: String { String(format: "%02d:%02d", hour, minute) }
}

// MARK: - Günün manifesti

/// Otomatik modda yerelleştirilmiş havuzdan gün sırasına göre manifest seçer;
/// kapalıysa kullanıcının kendi cümlesini döndürür.
enum ManifestProvider {
    static let poolSize = 10

    static func todaysManifest() -> String {
        let defaults = UserDefaults.standard
        let dailyMode = defaults.object(forKey: "dailyMode") == nil
            ? true
            : defaults.bool(forKey: "dailyMode")
        if dailyMode {
            let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            let key = "manifest_pool_\(day % poolSize)"
            return String(localized: String.LocalizationValue(key))
        }
        let custom = defaults.string(forKey: "manifest")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return custom.isEmpty ? String(localized: "default_manifest") : custom
    }
}

// MARK: - Arkaplan temaları

struct BgTheme: Identifiable {
    let key: String
    let colors: [Color]
    var id: String { key }
}

enum Themes {
    static let all: [BgTheme] = [
        BgTheme(key: "cosmic", colors: [
            Color(red: 0.17, green: 0.09, blue: 0.34),
            Color(red: 0.04, green: 0.04, blue: 0.13)
        ]),
        BgTheme(key: "sunrise", colors: [
            Color(red: 0.55, green: 0.24, blue: 0.18),
            Color(red: 0.28, green: 0.10, blue: 0.24),
            Color(red: 0.06, green: 0.04, blue: 0.12)
        ]),
        BgTheme(key: "ocean", colors: [
            Color(red: 0.04, green: 0.26, blue: 0.36),
            Color(red: 0.02, green: 0.07, blue: 0.20)
        ]),
        BgTheme(key: "forest", colors: [
            Color(red: 0.05, green: 0.28, blue: 0.18),
            Color(red: 0.02, green: 0.10, blue: 0.09)
        ]),
        BgTheme(key: "lavender", colors: [
            Color(red: 0.42, green: 0.31, blue: 0.58),
            Color(red: 0.13, green: 0.09, blue: 0.28)
        ])
    ]

    static func gradient(for key: String) -> LinearGradient {
        let theme = all.first { $0.key == key } ?? all[0]
        return LinearGradient(
            colors: theme.colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Uyku hesabı

enum SleepMath {
    /// Etkin alarmlar içinden bir sonraki çalacak olanı bulur.
    static func nextAlarm(
        _ alarms: [AlarmItem],
        from now: Date = Date()
    ) -> (date: Date, item: AlarmItem)? {
        let cal = Calendar.current
        var best: (Date, AlarmItem)?
        for item in alarms where item.enabled {
            var comps = DateComponents()
            comps.hour = item.hour
            comps.minute = item.minute
            guard let next = cal.nextDate(
                after: now, matching: comps, matchingPolicy: .nextTime
            ) else { continue }
            if best == nil || next < best!.0 {
                best = (next, item)
            }
        }
        return best.map { (date: $0.0, item: $0.1) }
    }

    /// Süreyi cihaz dilinde "7 sa 12 dk" gibi biçimler.
    static func format(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: max(0, interval)) ?? ""
    }

    static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Alarm deposu

@MainActor
final class AlarmStore: ObservableObject {
    @Published var alarms: [AlarmItem] = [] {
        didSet { persist() }
    }
    @Published var authProblem = false

    private let defaults = UserDefaults.standard

    init() {
        if let data = defaults.data(forKey: "alarmsJSON"),
           let items = try? JSONDecoder().decode([AlarmItem].self, from: data) {
            alarms = items
        } else if defaults.object(forKey: "enabled") != nil {
            // Eski tek alarmlı sürümden geçiş
            let item = AlarmItem(
                hour: defaults.object(forKey: "hour") == nil ? 8 : defaults.integer(forKey: "hour"),
                minute: defaults.integer(forKey: "minute"),
                enabled: defaults.bool(forKey: "enabled")
            )
            alarms = [item]
            if let oldID = defaults.string(forKey: "alarmID") {
                scheduledIDs = scheduledIDs + [oldID]
            }
            defaults.removeObject(forKey: "enabled")
            defaults.removeObject(forKey: "alarmID")
        }
    }

    // Sistemde kurulu alarm kimlikleri: senkronda önce hepsi iptal edilir
    private var scheduledIDs: [String] {
        get { defaults.stringArray(forKey: "scheduledIDs") ?? [] }
        set { defaults.set(newValue, forKey: "scheduledIDs") }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(alarms) {
            defaults.set(data, forKey: "alarmsJSON")
        }
    }

    func add(hour: Int, minute: Int) {
        alarms.append(AlarmItem(hour: hour, minute: minute))
        sortAlarms()
        sync()
    }

    func update(_ id: UUID, hour: Int, minute: Int) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].hour = hour
        alarms[index].minute = minute
        sortAlarms()
        sync()
    }

    func setEnabled(_ id: UUID, _ enabled: Bool) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].enabled = enabled
        sync()
    }

    func remove(at offsets: IndexSet) {
        alarms.remove(atOffsets: offsets)
        sync()
    }

    private func sortAlarms() {
        alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    func sync() {
        Task { await syncSchedules() }
    }

    /// Sistemdeki kayıtları listeyle eşitler: eskileri iptal eder,
    /// etkin olanları yeniden kurar.
    func syncSchedules() async {
        for idString in scheduledIDs {
            if let id = UUID(uuidString: idString) {
                await AlarmPlanner.cancel(id: id)
            }
        }
        var newIDs: [String] = []
        var denied = false
        for item in alarms where item.enabled {
            do {
                try await AlarmPlanner.schedule(item: item)
                newIDs.append(item.id.uuidString)
            } catch {
                denied = true
            }
        }
        scheduledIDs = newIDs
        authProblem = denied
    }
}
