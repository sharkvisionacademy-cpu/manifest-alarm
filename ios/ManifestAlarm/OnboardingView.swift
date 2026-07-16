import SwiftUI

// Manifest alanları: (kayıt anahtarı, çeviri anahtarı, simge)
let categoryOptions: [(key: String, label: String, icon: String)] = [
    ("all", "cat_all", "sparkles"),
    ("work", "cat_work", "briefcase.fill"),
    ("love", "cat_love", "heart.fill"),
    ("life", "cat_life", "leaf.fill")
]

/// İlk açılışta tema ve manifest alanı seçimi.
struct OnboardingView: View {
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("bgTheme") private var bgTheme = "cosmic"
    @AppStorage("manifestCategory") private var category = "all"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Palette.gold)
                    .padding(.top, 44)

                Text("welcome_title")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("welcome_sub")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))

                VStack(alignment: .leading, spacing: 14) {
                    Label("choose_theme", systemImage: "paintpalette.fill")
                        .font(.headline)
                        .foregroundStyle(Palette.gold)
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
                                    .frame(width: 48, height: 48)
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
                    Text(Themes.name(for: bgTheme))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 14) {
                    Label("choose_category", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(Palette.gold)
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(categoryOptions, id: \.key) { option in
                            Button {
                                category = option.key
                            } label: {
                                Label(
                                    String(localized: String.LocalizationValue(option.label)),
                                    systemImage: option.icon
                                )
                                .font(.callout.weight(.medium))
                                .foregroundStyle(
                                    category == option.key
                                        ? Color(red: 0.08, green: 0.08, blue: 0.20)
                                        : .white
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    category == option.key
                                        ? AnyShapeStyle(Palette.gold)
                                        : AnyShapeStyle(Color.white.opacity(0.08)),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    onboarded = true
                } label: {
                    Text("get_started")
                        .font(.title3.bold())
                        .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.gold)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Palette.background.ignoresSafeArea())
    }
}
