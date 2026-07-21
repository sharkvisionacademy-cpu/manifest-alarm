import Foundation
import AppIntents

/// Sistem alarm ekranındaki "Manifesti Söyle" düğmesi: uygulamayı açıp
/// konuşma ekranını gösterir.
struct OpenSpeechIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Say the Manifest"
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {}
    init(alarmID: String) {
        self.alarmID = alarmID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(alarmID, forKey: "ringingAlarmID")
        return .result()
    }
}

/// Sistem alarm ekranındaki zorunlu "Durdur" düğmesi. Bir koruma alarmı
/// manifest söylenmeden durdurulursa kendini yeniden kurar — böylece manifest
/// söylenene kadar 3 dakikada bir çalar. Erteleme (snooze) yoktur.
struct StopPenaltyIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Alarm"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    @Parameter(title: "Is Guard")
    var isGuard: Bool

    init() {}
    init(alarmID: String, isGuard: Bool = false) {
        self.alarmID = alarmID
        self.isGuard = isGuard
    }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults.standard
        let spoken = defaults.bool(forKey: "manifestSpoken")
        defaults.set(false, forKey: "manifestSpoken")
        defaults.removeObject(forKey: "ringingAlarmID")
        // Manifest söylenmeden bir koruma alarmı durdurulduysa zinciri sürdür.
        if isGuard && !spoken {
            try? await AlarmPlanner.scheduleGuard(after: 180)
        }
        return .result()
    }
}
