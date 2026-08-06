import SwiftUI

@main
struct ManifestAlarmApp: App {
    init() {
        // Seçili uygulama dilini, ilk görünüm yüklenmeden uygula.
        Bundle.setAppLanguage(UserDefaults.standard.string(forKey: "app_lang"))
        AdBootstrap.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Alarm ön planda çalınca konuşma ekranını zorla aç.
                    AlarmObserver.start()
                }
        }
    }
}
