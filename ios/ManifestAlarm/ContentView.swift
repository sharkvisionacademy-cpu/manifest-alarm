import SwiftUI
import AlarmKit

struct ContentView: View {
    @AppStorage("ringingAlarmID") private var ringingAlarmID = ""

    var body: some View {
        if ringingAlarmID.isEmpty {
            SettingsView()
        } else {
            SpeechDismissView()
        }
    }
}

// MARK: - Ayarlar ekranı

struct SettingsView: View {
    @AppStorage("hour") private var hour = 8
    @AppStorage("minute") private var minute = 0
    @AppStorage("manifest") private var manifest = ""
    @AppStorage("enabled") private var enabled = false
    @State private var time = Date()
    @State private var status = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("how_it_works")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("alarm_time") {
                    DatePicker(
                        "alarm_time",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                }
                Section("your_manifest") {
                    TextField(
                        String(localized: "default_manifest"),
                        text: $manifest,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                }
                Section {
                    Toggle("alarm_on", isOn: $enabled)
                    Button("save") { Task { await saveAll() } }
                    Button("test_alarm") { Task { await testNow() } }
                }
                if !status.isEmpty {
                    Section {
                        Text(status).font(.footnote)
                    }
                }
            }
            .navigationTitle("Manifest Alarm")
            .onAppear {
                var comps = DateComponents()
                comps.hour = hour
                comps.minute = minute
                time = Calendar.current.date(from: comps) ?? Date()
            }
        }
    }

    private func saveAll() async {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        hour = comps.hour ?? 8
        minute = comps.minute ?? 0
        _ = await SpeechService.requestPermissions()
        do {
            try await AlarmPlanner.rescheduleDaily(hour: hour, minute: minute, enabled: enabled)
            status = enabled
                ? String(localized: "saved")
                : String(localized: "alarm_off")
        } catch {
            status = String(localized: "auth_denied")
        }
    }

    private func testNow() async {
        _ = await SpeechService.requestPermissions()
        do {
            try await AlarmPlanner.scheduleOneShot(after: 10)
            status = String(localized: "test_scheduled")
        } catch {
            status = String(localized: "auth_denied")
        }
    }
}

// MARK: - Alarm kapatma (konuşma) ekranı

struct SpeechDismissView: View {
    @AppStorage("ringingAlarmID") private var ringingAlarmID = ""
    @AppStorage("manifest") private var manifest = ""
    @StateObject private var speech = SpeechService()
    @State private var similarity = 0.0
    @State private var success = false

    private var target: String {
        let t = manifest.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? String(localized: "default_manifest") : t
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("say_your_manifest")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 60)

            Text(target)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(AlarmPlanner.tint)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

            if success {
                Text("success")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
            } else {
                Button {
                    speech.start()
                } label: {
                    Label(
                        speech.isListening
                            ? String(localized: "listening")
                            : String(localized: "start_listening"),
                        systemImage: "mic.fill"
                    )
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(AlarmPlanner.tint)
                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.2))
                .disabled(speech.isListening)

                Text(speech.transcript)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                if similarity > 0 {
                    Text(String(
                        format: String(localized: "similar_percent"),
                        Int(similarity * 100)
                    ))
                    .foregroundStyle(.white)
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.14, blue: 0.35),
                    Color(red: 0.08, green: 0.08, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onChange(of: speech.transcript) { _, newValue in
            guard !success, !newValue.isEmpty else { return }
            similarity = SpeechMatcher.similarity(expected: target, spoken: newValue)
            if similarity >= SpeechMatcher.threshold {
                finish()
            }
        }
        .onAppear {
            speech.start()
        }
    }

    private func finish() {
        success = true
        speech.stop()
        UserDefaults.standard.set(true, forKey: "manifestSpoken")
        AlarmPlanner.stopRinging(idString: ringingAlarmID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UserDefaults.standard.set(false, forKey: "manifestSpoken")
            ringingAlarmID = ""
        }
    }
}
