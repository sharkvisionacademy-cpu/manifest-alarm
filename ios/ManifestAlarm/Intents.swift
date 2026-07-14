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

/// Sistem alarm ekranındaki zorunlu "Durdur" düğmesi: manifest söylenmeden
/// basıldıysa ceza olarak 2 dakika sonra yeni bir alarm kurar.
struct StopPenaltyIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Alarm"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {}
    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "manifestSpoken") {
            try? await AlarmPlanner.scheduleOneShot(after: 120)
        }
        defaults.set(false, forKey: "manifestSpoken")
        defaults.removeObject(forKey: "ringingAlarmID")
        return .result()
    }
}
