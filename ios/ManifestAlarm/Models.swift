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
