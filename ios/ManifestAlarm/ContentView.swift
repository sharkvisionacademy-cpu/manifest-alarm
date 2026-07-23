import SwiftUI
import AlarmKit
import AVFoundation

// Alarm sesi seçenekleri: (kayıt anahtarı, çeviri anahtarı)
let soundOptions: [(key: String, label: String)] = [
    ("default", "sound_default"),
    ("freq432", "sound_432"),
    ("freq528", "sound_528"),
    ("freq639", "sound_639"),
    ("freq852", "sound_852"),
    ("musicbox", "sound_musicbox"),
    ("bowl", "sound_bowl"),
    ("om136", "sound_om"),
    ("piano", "sound_piano"),
    ("harp", "sound_harp"),
    ("chimes", "sound_chimes"),
    ("marimba", "sound_marimba")
]

// MARK: - Renk paleti (enerji/frekans teması)

enum Palette {
    static let gold = Color(red: 1.0, green: 0.79, blue: 0.30)
    static let night = Color(red: 0.04, green: 0.04, blue: 0.13)
    static let violet = Color(red: 0.17, green: 0.09, blue: 0.34)
    static let card = Color.white.opacity(0.08)

    // Seçili arkaplan teması tüm ekranlarda kullanılır
    static var background: LinearGradient {
        Themes.gradient(for: UserDefaults.standard.string(forKey: "bgTheme") ?? "cosmic")
    }
}

// MARK: - Kök görünüm

struct ContentView: View {
    @AppStorage("ringingAlarmID") private var ringingAlarmID = ""
    @AppStorage("onboarded") private var onboarded = false

    var body: some View {
        Group {
            if !ringingAlarmID.isEmpty {
                SpeechDismissView()
            } else if !onboarded {
                OnboardingView()
            } else {
                HomeView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Ana ekran: bugünün manifesti + alarm listesi

struct HomeView: View {
    @StateObject private var store = AlarmStore()
    @AppStorage("dailyMode") private var dailyMode = true
    @AppStorage("manifest") private var customManifest = ""
    @AppStorage("alarmSound") private var alarmSound = "default"
    @AppStorage("bgTheme") private var bgTheme = "cosmic"
    @AppStorage("sleepGoal") private var sleepGoal = 8.0
    @AppStorage("manifestCategory") private var manifestCategory = "all"
    @State private var showAdd = false
    @State private var editing: AlarmItem?
    @State private var status = ""
    @State private var previewPlayer: AVAudioPlayer?
    @State private var previewing = false
    @ObservedObject private var subs = SubscriptionManager.shared
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                manifestSection
                sleepSection
                alarmsSection
                manifestSettingsSection
                if !subs.isPremium { premiumSection }
                soundSection
                themeSection
                footerSection
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Manifest Alarm")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AlarmEditSheet(store: store, item: nil)
            }
            .sheet(item: $editing) { item in
                AlarmEditSheet(store: store, item: item)
            }
            .onAppear { store.sync() }
            .safeAreaInset(edge: .bottom) {
                if !subs.isPremium {
                    BannerContainer()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .tint(Palette.gold)
    }

    // MARK: - Premium tanıtım kartı (abone değilse görünür)

    private var premiumSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Palette.gold)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("premium_upsell_title")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("premium_upsell_sub")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.vertical, 4)
            }
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(Palette.violet.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Palette.gold.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var manifestSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("todays_manifest", systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.gold)
                Text(ManifestProvider.todaysManifest())
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Palette.gold.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Palette.gold.opacity(0.25), radius: 10)
        )
    }

    private var categoryPickerOptions: [(key: String, label: String, icon: String)] {
        subs.isPremium ? categoryOptions + premiumCategoryOptions : categoryOptions
    }

    private var manifestSettingsSection: some View {
        Section {
            Toggle(isOn: $dailyMode) {
                Label("daily_mode", systemImage: "waveform")
                    .foregroundStyle(.white)
            }
            if dailyMode {
                Picker(selection: $manifestCategory) {
                    ForEach(categoryPickerOptions, id: \.key) { option in
                        Text(LocalizedStringKey(option.label)).tag(option.key)
                    }
                } label: {
                    Label("manifest_category", systemImage: "square.grid.2x2.fill")
                        .foregroundStyle(.white)
                }
                .pickerStyle(.menu)
            }
            if !dailyMode {
                TextField(
                    String(localized: "default_manifest"),
                    text: $customManifest,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .foregroundStyle(.white)
            }
        } footer: {
            Text("how_it_works")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.55))
        }
        .listRowBackground(Palette.card)
    }

    private var sleepSection: some View {
        Section {
            if let next = SleepMath.nextAlarm(store.alarms) {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let interval = next.date.timeIntervalSince(context.date)
                    let goalSeconds = sleepGoal * 3600
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("sleep_title", systemImage: "moon.zzz.fill")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.gold)
                            Spacer()
                            Text("\(String(localized: "next_alarm_label")): \(next.item.timeText)")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Text(String(
                            format: String(localized: "sleep_if_now"),
                            SleepMath.format(interval)
                        ))
                        .font(.headline)
                        .foregroundStyle(interval >= goalSeconds ? Color.green : Palette.gold)
                        ProgressView(value: min(interval / goalSeconds, 1.0))
                            .tint(interval >= goalSeconds ? .green : Palette.gold)
                        Text(String(
                            format: String(localized: "bedtime_for_goal"),
                            SleepMath.timeString(next.date.addingTimeInterval(-goalSeconds))
                        ))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.vertical, 6)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(
                        format: String(localized: "sleep_goal"),
                        SleepMath.format(sleepGoal * 3600)
                    ))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                    Slider(value: $sleepGoal, in: 5...10, step: 0.5)
                        .tint(Palette.gold)
                }
            } else {
                Text("no_alarm_for_sleep")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .listRowBackground(Palette.card)
    }

    private var themeSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Themes.all) { theme in
                        Button {
                            bgTheme = theme.key
                        } label: {
                            Circle()
                                .fill(LinearGradient(
                                    colors: theme.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Circle().strokeBorder(
                                        bgTheme == theme.key
                                            ? Palette.gold
                                            : .white.opacity(0.25),
                                        lineWidth: bgTheme == theme.key ? 3 : 1
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            Text(Themes.name(for: bgTheme))
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        } header: {
            Label("background_title", systemImage: "paintpalette.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.gold)
        }
        .listRowBackground(Palette.card)
    }

    private var soundSection: some View {
        Section {
            Picker(selection: $alarmSound) {
                ForEach(soundOptions, id: \.key) { option in
                    Text(LocalizedStringKey(option.label)).tag(option.key)
                }
            } label: {
                Label("alarm_sound", systemImage: "speaker.wave.2.fill")
                    .foregroundStyle(.white)
            }
            .pickerStyle(.menu)
            .onChange(of: alarmSound) { _, _ in
                stopPreview()
                store.sync()
            }
            if alarmSound != "default" {
                Button {
                    togglePreview()
                } label: {
                    Label(
                        previewing
                            ? String(localized: "stop_preview")
                            : String(localized: "preview"),
                        systemImage: previewing ? "stop.circle.fill" : "play.circle.fill"
                    )
                    .foregroundStyle(Palette.gold)
                }
            }
        }
        .listRowBackground(Palette.card)
    }

    private func togglePreview() {
        if previewing {
            stopPreview()
            return
        }
        guard let url = Bundle.main.url(forResource: alarmSound, withExtension: "wav") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        previewPlayer = try? AVAudioPlayer(contentsOf: url)
        previewPlayer?.play()
        previewing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 21) {
            if previewing { stopPreview() }
        }
    }

    private func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        previewing = false
    }

    private var alarmsSection: some View {
        Section {
            if store.alarms.isEmpty {
                Text("no_alarms")
                    .foregroundStyle(.white.opacity(0.55))
                    .font(.callout)
            }
            ForEach(store.alarms) { item in
                AlarmRow(item: item, store: store)
                    .contentShape(Rectangle())
                    .onTapGesture { editing = item }
            }
            .onDelete { store.remove(at: $0) }
        } header: {
            Label("alarms_title", systemImage: "alarm.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.gold)
        }
        .listRowBackground(Palette.card)
    }

    private var footerSection: some View {
        Section {
            Button {
                Task { await testNow() }
            } label: {
                Label("test_alarm", systemImage: "bell.and.waves.left.and.right")
                    .foregroundStyle(Palette.gold)
            }
            if !status.isEmpty {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
            if store.authProblem {
                Text("auth_denied")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .listRowBackground(Palette.card)
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

// MARK: - Alarm satırı (Apple saat uygulaması tarzı)

struct AlarmRow: View {
    let item: AlarmItem
    @ObservedObject var store: AlarmStore

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.timeText)
                    .font(.system(size: 46, weight: .light, design: .rounded))
                    .foregroundStyle(item.enabled ? .white : .white.opacity(0.35))
                Text("every_day")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(item.enabled ? 0.6 : 0.3))
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { item.enabled },
                set: { store.setEnabled(item.id, $0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Alarm ekleme/düzenleme sayfası

struct AlarmEditSheet: View {
    @ObservedObject var store: AlarmStore
    let item: AlarmItem?
    @Environment(\.dismiss) private var dismiss
    @State private var time = Date()

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.top, 16)
                // Seçilen saate göre canlı uyku süresi
                Label(
                    String(
                        format: String(localized: "sleep_if_now"),
                        SleepMath.format(nextOccurrence(of: time).timeIntervalSinceNow)
                    ),
                    systemImage: "moon.zzz.fill"
                )
                .font(.callout.weight(.medium))
                .foregroundStyle(Palette.gold)
                .padding(.top, 4)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle(Text("add_alarm"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel_btn") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { saveAndClose() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                var comps = DateComponents()
                comps.hour = item?.hour ?? 8
                comps.minute = item?.minute ?? 0
                time = Calendar.current.date(from: comps) ?? Date()
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
        .tint(Palette.gold)
    }

    private func nextOccurrence(of date: Date) -> Date {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Calendar.current.nextDate(
            after: Date(), matching: comps, matchingPolicy: .nextTime
        ) ?? date
    }

    private func saveAndClose() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        Task { _ = await SpeechService.requestPermissions() }
        if let item {
            store.update(item.id, hour: comps.hour ?? 8, minute: comps.minute ?? 0)
        } else {
            store.add(hour: comps.hour ?? 8, minute: comps.minute ?? 0)
        }
        dismiss()
    }
}

// MARK: - Alarm kapatma (konuşma) ekranı

struct SpeechDismissView: View {
    @AppStorage("ringingAlarmID") private var ringingAlarmID = ""
    @AppStorage("alarmSound") private var alarmSound = "default"
    @StateObject private var speech = SpeechService()
    @State private var similarity = 0.0
    @State private var success = false
    @State private var target = ManifestProvider.todaysManifest()
    @State private var loopPlayer: AVAudioPlayer?
    @State private var escalateWork: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 24) {
            Text(Date(), style: .time)
                .font(.system(size: 64, weight: .light, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 40)

            Text("say_your_manifest")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Palette.gold)
                Text(target)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.gold)
                    .lineSpacing(4)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Palette.gold.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Palette.gold.opacity(0.3), radius: 14)
            )

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
                        systemImage: speech.isListening ? "waveform" : "mic.fill"
                    )
                    .font(.title2.bold())
                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.20))
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.gold)
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
        .background(Palette.background.ignoresSafeArea())
        .onChange(of: speech.transcript) { _, newValue in
            guard !success, !newValue.isEmpty else { return }
            similarity = SpeechMatcher.similarity(expected: target, spoken: newValue)
            if similarity >= SpeechMatcher.threshold {
                finish()
            }
        }
        .onAppear {
            speech.start()
            startUrgencySound()
        }
        .onDisappear {
            stopUrgencySound()
            speech.stop()
        }
    }

    /// Konuşma ekranı açıkken alarm sesini kısık, döngüde çalar; manifest söylenince susar.
    /// 10 saniye içinde söylenmezse ses yeniden tam seviyeye çıkar (baskı geri gelir).
    private func startUrgencySound() {
        let file = alarmSound == "default" ? "chimes" : alarmSound
        guard let url = Bundle.main.url(forResource: file, withExtension: "wav") else { return }
        loopPlayer = try? AVAudioPlayer(contentsOf: url)
        loopPlayer?.numberOfLoops = -1
        loopPlayer?.volume = 0.55
        loopPlayer?.prepareToPlay()
        loopPlayer?.play()

        // 10 sn içinde manifest söylenmezse tam sese çık
        let work = DispatchWorkItem { [self] in
            loopPlayer?.volume = 1.0
        }
        escalateWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: work)
    }

    private func stopUrgencySound() {
        escalateWork?.cancel()
        escalateWork = nil
        loopPlayer?.stop()
        loopPlayer = nil
    }

    private func finish() {
        success = true
        stopUrgencySound()
        speech.stop()
        UserDefaults.standard.set(true, forKey: "manifestSpoken")
        AlarmPlanner.stopRinging(idString: ringingAlarmID)
        // Manifest söylendi: koruma alarmlarını yarına taşı
        Task { await AlarmPlanner.resyncShadows() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UserDefaults.standard.set(false, forKey: "manifestSpoken")
            ringingAlarmID = ""
        }
    }
}
