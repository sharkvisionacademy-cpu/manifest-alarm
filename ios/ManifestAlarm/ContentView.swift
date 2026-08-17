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
    ("marimba", "sound_marimba"),
    // Premium sesler
    ("freq963", "sound_963"),
    ("freq396", "sound_396"),
    ("crystal", "sound_crystal"),
    ("celesta", "sound_celesta")
]

// Yalnızca abonelerde seçilebilen premium sesler.
let premiumSoundKeys: Set<String> = ["freq963", "freq396", "crystal", "celesta"]

// MARK: - Renk paleti (enerji/frekans teması)

enum Palette {
    static let gold = Color(red: 1.0, green: 0.79, blue: 0.30)
    static let night = Color(red: 0.04, green: 0.04, blue: 0.13)
    static let violet = Color(red: 0.17, green: 0.09, blue: 0.34)
    static let card = Color.white.opacity(0.08)

    // Seçili arkaplan teması tüm ekranlarda kullanılır.
    // Premium tema seçiliyken abonelik biterse "cosmic"e düşer.
    static var background: LinearGradient {
        let key = UserDefaults.standard.string(forKey: "bgTheme") ?? "cosmic"
        let active = UserDefaults.standard.bool(forKey: "premiumActive")
        let effective = (Themes.isPremium(key) && !active) ? "cosmic" : key
        return Themes.gradient(for: effective)
    }
}

// MARK: - Kök görünüm

struct ContentView: View {
    @AppStorage("ringingAlarmID") private var ringingAlarmID = ""
    @AppStorage("onboarded") private var onboarded = false
    @ObservedObject private var lang = LanguageManager.shared
    @Environment(\.scenePhase) private var scenePhase

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
        // Dil değişince tüm ağacı yeniden çiz (String(localized:) tazelensin)
        .id(lang.code)
        .environment(\.locale, lang.locale)
        .preferredColorScheme(.dark)
        // Alarm ekranındaki "Manifesti Söyle" uygulamayı açtığında (OpenSpeechIntent),
        // UserDefaults'a yazılan ringingAlarmID @AppStorage'a hemen yansımayabiliyor.
        // Uygulama öne geldiğinde değeri tazeleyip konuşma ekranını güvenilir şekilde aç.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let current = UserDefaults.standard.string(forKey: "ringingAlarmID") ?? ""
            if current != ringingAlarmID { ringingAlarmID = current }
        }
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
    // Gün içi manifest hatırlatıcıları (ücretsiz)
    @AppStorage("remNoonOn") private var remNoonOn = false
    @AppStorage("remNoonMin") private var remNoonMin = 13 * 60
    @AppStorage("remDayOn") private var remDayOn = false
    @AppStorage("remDayMin") private var remDayMin = 16 * 60
    @AppStorage("remSleepOn") private var remSleepOn = false
    @AppStorage("remSleepMin") private var remSleepMin = 22 * 60 + 30
    @State private var showAdd = false
    @State private var editing: AlarmItem?
    @State private var status = ""
    @State private var previewPlayer: AVAudioPlayer?
    @State private var previewing = false
    @ObservedObject private var subs = SubscriptionManager.shared
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var prompt = PromptCoordinator.shared
    @State private var showPaywall = false
    @State private var showCustomAffirmations = false

    var body: some View {
        NavigationStack {
            List {
                manifestSection
                if subs.isPremium { streakSection }
                sleepSection
                alarmsSection
                manifestSettingsSection
                reminderSection
                if !subs.isPremium { premiumSection }
                soundSection
                themeSection
                languageSection
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
            .onAppear {
                store.sync()
                // Hatırlatıcıları güncel manifestlerle yeniden zamanla.
                ReminderManager.reschedule()
                // Alarm başarıyla kapatıldıysa, uygulamaya dönüşte tam ekran reklam göster.
                if UserDefaults.standard.bool(forKey: "showAdAfterAlarm") {
                    UserDefaults.standard.set(false, forKey: "showAdAfterAlarm")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        InterstitialManager.shared.maybeShow()
                    }
                } else {
                    InterstitialManager.shared.preload()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !subs.isPremium {
                    BannerContainer()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showCustomAffirmations) {
                CustomAffirmationsSheet()
            }
            .onChange(of: prompt.showPremiumPrompt) { _, show in
                // Reklamdan sonra gelen aralıklı öneriyi paywall olarak aç.
                if show {
                    prompt.showPremiumPrompt = false
                    showPaywall = true
                }
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

    // MARK: - Seri (streak) kartı — premium

    private var streakSection: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(Palette.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: String(localized: "streak_days"), StreakTracker.displayCurrent))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(String(format: String(localized: "streak_best"), StreakTracker.best))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
            }
            .padding(.vertical, 4)
        } header: {
            Label("streak_title", systemImage: "flame.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.gold)
        }
        .listRowBackground(Palette.card)
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

    private func themeLocked(_ theme: BgTheme) -> Bool {
        theme.isPremium && !subs.isPremium
    }

    private func soundLabel(_ option: (key: String, label: String)) -> String {
        let name = String(localized: String.LocalizationValue(option.label))
        return (premiumSoundKeys.contains(option.key) && !subs.isPremium) ? "\(name) 🔒" : name
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
                if manifestCategory == "custom" && subs.isPremium {
                    Button {
                        showCustomAffirmations = true
                    } label: {
                        Label("custom_manage", systemImage: "square.and.pencil")
                            .foregroundStyle(Palette.gold)
                    }
                }
            }
            if !dailyMode {
                TextField(
                    NSLocalizedString("default_manifest", comment: ""),
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

    // MARK: - Gün içi manifest hatırlatıcıları (ücretsiz)

    private var reminderSection: some View {
        Section {
            reminderRow("reminder_noon", "sun.max.fill", isOn: $remNoonOn, minutes: $remNoonMin)
            reminderRow("reminder_day", "sun.haze.fill", isOn: $remDayOn, minutes: $remDayMin)
            reminderRow("reminder_sleep", "moon.stars.fill", isOn: $remSleepOn, minutes: $remSleepMin)
        } header: {
            Label("reminder_section_title", systemImage: "bell.badge.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.gold)
        } footer: {
            Text("reminder_footer")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.55))
        }
        .listRowBackground(Palette.card)
    }

    @ViewBuilder
    private func reminderRow(
        _ titleKey: LocalizedStringKey,
        _ icon: String,
        isOn: Binding<Bool>,
        minutes: Binding<Int>
    ) -> some View {
        Toggle(isOn: isOn) {
            Label(titleKey, systemImage: icon).foregroundStyle(.white)
        }
        .onChange(of: isOn.wrappedValue) { _, on in
            if on { ReminderManager.requestAuthorizationIfNeeded() }
            ReminderManager.reschedule()
        }
        if isOn.wrappedValue {
            DatePicker("", selection: timeBinding(minutes), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .onChange(of: minutes.wrappedValue) { _, _ in ReminderManager.reschedule() }
        }
    }

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = minutes.wrappedValue / 60
                c.minute = minutes.wrappedValue % 60
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { newDate in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                minutes.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            }
        )
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
                            if themeLocked(theme) {
                                showPaywall = true
                            } else {
                                bgTheme = theme.key
                            }
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
                                .overlay {
                                    if themeLocked(theme) {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                            .padding(5)
                                            .background(Circle().fill(.black.opacity(0.5)))
                                    }
                                }
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
                    Text(soundLabel(option)).tag(option.key)
                }
            } label: {
                Label("alarm_sound", systemImage: "speaker.wave.2.fill")
                    .foregroundStyle(.white)
            }
            .pickerStyle(.menu)
            .onChange(of: alarmSound) { oldValue, newValue in
                // Premium ses abone olmayanlarca seçilemez: geri al + paywall aç.
                if premiumSoundKeys.contains(newValue) && !subs.isPremium {
                    alarmSound = oldValue
                    showPaywall = true
                    return
                }
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

    // MARK: - Dil seçimi

    private var languageSection: some View {
        Section {
            Picker(selection: Binding(
                get: { lang.code },
                set: { lang.code = $0 }
            )) {
                ForEach(LanguageManager.supported, id: \.code) { item in
                    Text(item.code.isEmpty ? String(localized: "lang_system") : item.name)
                        .tag(item.code)
                }
            } label: {
                Label("language", systemImage: "globe")
                    .foregroundStyle(.white)
            }
            .pickerStyle(.menu)
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
        // Alarm kaydedildikten sonra (sayfa kapanınca) tam ekran reklam göster.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            InterstitialManager.shared.maybeShow()
        }
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
            // Kullanıcı manifest söylerken sonraki reklamı hazırla (dönüşte hemen çıksın).
            InterstitialManager.shared.preload()
        }
        .onDisappear {
            stopUrgencySound()
            speech.stop()
        }
    }

    /// Konuşma ekranı açıkken alarm sesini ÇOK KISIK, döngüde çalar; manifest söylenince susar.
    /// Ses düşük tutulur çünkü yüksek sesle çalan alarm mikrofona sızıp konuşma tanımayı
    /// boğuyordu (kullanıcı bu ekranda zaten uyanık). 10 sn içinde söylenmezse ses yükselir.
    /// Ayrıca hafif gecikmeyle başlatılır ki ses tanıma motoru (mikrofon) önce oturisin.
    private func startUrgencySound() {
        let file = alarmSound == "default" ? "chimes" : alarmSound
        guard let url = Bundle.main.url(forResource: file, withExtension: "wav") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            loopPlayer = try? AVAudioPlayer(contentsOf: url)
            loopPlayer?.numberOfLoops = -1
            loopPlayer?.volume = 0.18
            loopPlayer?.prepareToPlay()
            loopPlayer?.play()
        }

        // 10 sn içinde manifest söylenmezse baskıyı artır (yine de tanımayı boğmayacak seviye).
        let work = DispatchWorkItem { [self] in
            loopPlayer?.volume = 0.55
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
        // Günlük seriyi güncelle (manifest başarıyla söylendi).
        StreakTracker.recordCompletion()
        // Manifesti söyledik: gösterilen manifest bir sonrakine geçsin.
        ManifestProvider.advance()
        // Uygulamaya dönünce (HomeView) tam ekran reklam göstermek için işaretle.
        UserDefaults.standard.set(true, forKey: "showAdAfterAlarm")
        AlarmPlanner.stopRinging(idString: ringingAlarmID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UserDefaults.standard.set(false, forKey: "manifestSpoken")
            ringingAlarmID = ""
        }
    }
}
