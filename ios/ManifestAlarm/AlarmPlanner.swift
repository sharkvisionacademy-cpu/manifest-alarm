import Foundation
import SwiftUI
import AlarmKit
import ActivityKit

struct ManifestMetadata: AlarmMetadata {
    init() {}
}

enum PlanError: Error {
    case denied
}

/// AlarmKit üzerinden alarm kurma/durdurma işlemleri.
enum AlarmPlanner {

    static let tint = Color(red: 1.0, green: 0.79, blue: 0.30)

    private static let everyDay: [Locale.Weekday] = [
        .sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday
    ]

    static func ensureAuthorized() async throws {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return
        case .notDetermined:
            let state = try await manager.requestAuthorization()
            guard state == .authorized else { throw PlanError.denied }
        default:
            throw PlanError.denied
        }
    }

    private static func attributes() -> AlarmAttributes<ManifestMetadata> {
        let stopButton = AlarmButton(
            text: LocalizedStringResource("alert_stop"),
            textColor: .white,
            systemImageName: "xmark.circle.fill"
        )
        let speakButton = AlarmButton(
            text: LocalizedStringResource("alert_speak"),
            textColor: Color(red: 0.08, green: 0.08, blue: 0.20),
            systemImageName: "mic.fill"
        )
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource("alert_title"),
            stopButton: stopButton,
            secondaryButton: speakButton,
            secondaryButtonBehavior: .custom
        )
        return AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            tintColor: tint
        )
    }

    /// Kullanıcının seçtiği alarm sesi ("default" ya da paket içindeki frekans dosyası).
    private static func currentSound() -> AlertConfiguration.AlertSound {
        let name = UserDefaults.standard.string(forKey: "alarmSound") ?? "default"
        return name == "default" ? .default : .named("\(name).wav")
    }

    /// Her gün, belirtilen saatte tekrarlayan alarm kurar.
    static func schedule(item: AlarmItem) async throws {
        try await ensureAuthorized()
        let time = Alarm.Schedule.Relative.Time(hour: item.hour, minute: item.minute)
        let schedule = Alarm.Schedule.relative(
            Alarm.Schedule.Relative(time: time, repeats: .weekly(everyDay))
        )
        let configuration = AlarmManager.AlarmConfiguration(
            schedule: schedule,
            attributes: attributes(),
            stopIntent: StopPenaltyIntent(alarmID: item.id.uuidString),
            secondaryIntent: OpenSpeechIntent(alarmID: item.id.uuidString),
            sound: currentSound()
        )
        try await AlarmManager.shared.schedule(id: item.id, configuration: configuration)
    }

    static func cancel(id: UUID) async {
        try? await AlarmManager.shared.cancel(id: id)
    }

    /// Tek seferlik alarm: test için ve manifest söylenmeden durdurma cezası için.
    static func scheduleOneShot(after seconds: TimeInterval) async throws {
        try await ensureAuthorized()
        let id = UUID()
        let configuration = AlarmManager.AlarmConfiguration(
            schedule: .fixed(Date().addingTimeInterval(seconds)),
            attributes: attributes(),
            stopIntent: StopPenaltyIntent(alarmID: id.uuidString),
            secondaryIntent: OpenSpeechIntent(alarmID: id.uuidString),
            sound: currentSound()
        )
        try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    static func stopRinging(idString: String) {
        guard let id = UUID(uuidString: idString) else { return }
        try? AlarmManager.shared.stop(id: id)
    }

    /// Koruma alarmları: her etkin alarmın bir sonraki çalışından 3 dk sonrasına
    /// tek seferlik yedek kurulur. Manifest söylenmeden alarm nasıl susturulursa
    /// susturulsun (ses tuşu, Durdur) koruma bir kez daha çalar. Manifest
    /// söylenince yeniden eşitlenir ve yarına taşınır.
    static func resyncShadows() async {
        let defaults = UserDefaults.standard
        for idString in defaults.stringArray(forKey: "shadowIDs") ?? [] {
            if let id = UUID(uuidString: idString) {
                await cancel(id: id)
            }
        }
        var newIDs: [String] = []
        if let data = defaults.data(forKey: "alarmsJSON"),
           let items = try? JSONDecoder().decode([AlarmItem].self, from: data) {
            for item in items where item.enabled {
                guard let next = SleepMath.nextAlarm([item]) else { continue }
                let id = UUID()
                let configuration = AlarmManager.AlarmConfiguration(
                    schedule: .fixed(next.date.addingTimeInterval(180)),
                    attributes: attributes(),
                    stopIntent: StopPenaltyIntent(alarmID: id.uuidString),
                    secondaryIntent: OpenSpeechIntent(alarmID: id.uuidString),
                    sound: currentSound()
                )
                if (try? await AlarmManager.shared.schedule(id: id, configuration: configuration)) != nil {
                    newIDs.append(id.uuidString)
                }
            }
        }
        defaults.set(newIDs, forKey: "shadowIDs")
    }
}
