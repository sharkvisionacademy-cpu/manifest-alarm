import SwiftUI

/// Kullanıcının kendi olumlamalarını saklar (premium özelliği).
enum CustomAffirmations {
    private static let key = "customAffirmations"

    static func load() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return list
    }

    static func save(_ list: [String]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

/// Kendi olumlamalarını ekleyip silmek için yönetim ekranı.
struct CustomAffirmationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var items: [String] = CustomAffirmations.load()
    @State private var newText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        TextField(
                            String(localized: "custom_add_placeholder"),
                            text: $newText,
                            axis: .vertical
                        )
                        .lineLimit(1...3)
                        .foregroundStyle(.white)
                        Button {
                            add()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Palette.gold)
                        }
                        .disabled(newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } footer: {
                    Text("custom_footer")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .listRowBackground(Palette.card)

                Section {
                    if items.isEmpty {
                        Text("custom_empty")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    ForEach(items.indices, id: \.self) { i in
                        Text(items[i])
                            .foregroundStyle(.white)
                            .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        items.remove(atOffsets: offsets)
                        CustomAffirmations.save(items)
                    }
                } header: {
                    Label("custom_list_header", systemImage: "list.bullet")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.gold)
                }
                .listRowBackground(Palette.card)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("custom_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Palette.gold)
    }

    private func add() {
        let text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        items.append(text)
        newText = ""
        CustomAffirmations.save(items)
    }
}
