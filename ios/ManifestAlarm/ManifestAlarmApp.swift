import SwiftUI

@main
struct ManifestAlarmApp: App {
    init() {
        AdBootstrap.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
