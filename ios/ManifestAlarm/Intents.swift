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

/// Sistem alarm ekranındaki zorunlu "Durdur" düğmesi. Tekrar çalma işini
/// koruma alarmı (resyncShadows) üstlendiği için burada sadece durum temizlenir.
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
        // Ceza artık koruma alarmıyla (resyncShadows) tek tip:
        // manifest söylenmeden durdurulan her alarm 3 dk sonra bir kez daha çalar.
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "manifestSpoken")
        defaults.removeObject(forKey: "ringingAlarmID")
        return .result()
    }
}
