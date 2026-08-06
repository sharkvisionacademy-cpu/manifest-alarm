import Foundation
import AlarmKit

/// Alarm ön planda (uygulama açık / telefon kilitli değilken) çaldığında,
/// konuşma (manifest) ekranını zorla açar.
///
/// Neden gerekli: Bu durumda sistem alarmı üstten inen bir banner olarak
/// görünür. Banner itilip/kaydırılıp kapatılırsa "Durdur" (StopPenaltyIntent)
/// tetiklenmez ve koruma zinciri devreye girmeden alarm susabilir. Bu gözlemci,
/// alarm "alerting" durumuna geçtiği an konuşma ekranını açarak manifest
/// söylenmeden kapanmasını engeller.
@MainActor
enum AlarmObserver {
    private static var task: Task<Void, Never>?

    static func start() {
        guard task == nil else { return }
        task = Task {
            for await alarms in AlarmManager.shared.alarmUpdates {
                guard alarms.contains(where: { $0.state == .alerting }) else { continue }
                let alerting = alarms.first { $0.state == .alerting }!
                let defaults = UserDefaults.standard
                let alreadyShowing = !(defaults.string(forKey: "ringingAlarmID") ?? "").isEmpty
                // Ekran zaten açıksa ya da manifest yeni söylendiyse tekrar açma.
                if !alreadyShowing && !defaults.bool(forKey: "manifestSpoken") {
                    defaults.set(alerting.id.uuidString, forKey: "ringingAlarmID")
                }
            }
        }
    }
}
