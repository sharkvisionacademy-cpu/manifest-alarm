import Foundation

private var associatedLanguageBundle: UInt8 = 0

/// Bundle.main'in dil paketini, uygulama içi seçime göre değiştirir.
/// Böylece NSLocalizedString / String(localized:) çağrıları seçilen dili döndürür
/// (telefonun sistem dilinden bağımsız, yeniden başlatma gerekmez).
final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &associatedLanguageBundle) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Seçilen dilin .lproj paketini Bundle.main'e bağlar. nil = sistem dili.
    static func setAppLanguage(_ language: String?) {
        if !(Bundle.main is LocalizedBundle) {
            object_setClass(Bundle.main, LocalizedBundle.self)
        }
        var target: Bundle?
        if let language, !language.isEmpty,
           let path = Bundle.main.path(forResource: language, ofType: "lproj") {
            target = Bundle(path: path)
        }
        objc_setAssociatedObject(
            Bundle.main, &associatedLanguageBundle, target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

/// Uygulama içi dil seçimini yönetir.
@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// Desteklenen diller: (kod, yerel/özerk ad). "" = sistem dili.
    static let supported: [(code: String, name: String)] = [
        ("", "lang_system"),
        ("tr", "Türkçe"),
        ("en", "English"),
        ("de", "Deutsch"),
        ("es", "Español"),
        ("fr", "Français"),
        ("it", "Italiano"),
        ("pt", "Português"),
        ("ru", "Русский"),
        ("ar", "العربية"),
        ("hi", "हिन्दी"),
        ("id", "Bahasa Indonesia"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("zh-Hans", "简体中文")
    ]

    @Published var code: String {
        didSet {
            UserDefaults.standard.set(code, forKey: "app_lang")
            Bundle.setAppLanguage(code)
        }
    }

    private init() {
        code = UserDefaults.standard.string(forKey: "app_lang") ?? ""
        Bundle.setAppLanguage(code)
    }

    /// SwiftUI Text(LocalizedStringKey) için etkin yerel ayar.
    var locale: Locale {
        code.isEmpty ? .autoupdatingCurrent : Locale(identifier: code)
    }
}
