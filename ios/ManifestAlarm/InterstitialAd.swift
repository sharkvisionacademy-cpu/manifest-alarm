import GoogleMobileAds
import UIKit

// AdConfig'i tam ekran (interstitial) reklam kimlikleriyle genişletir.
extension AdConfig {
    /// AdMob panelinden alınan GERÇEK interstitial reklam birimi ("Manifest Interstitial").
    static let realInterstitialID = "ca-app-pub-6959840143670078/3683039766"
    /// Google'ın resmi test interstitial birimi.
    static let testInterstitialID = "ca-app-pub-3940256099942544/4411468910"

    static var interstitialID: String { isTestEnvironment ? testInterstitialID : realInterstitialID }
}

/// Tam ekran geçiş reklamlarını (interstitial) yönetir.
/// - Yalnızca doğal geçişlerde gösterilir: alarm kaydedildikten sonra ve
///   alarm çalıp kapatıldıktan sonra uygulamaya dönünce.
/// - ALARM ÇALARKEN / alarm ekranında ASLA gösterilmez.
/// - Premium kullanıcıda kapalıdır; ayrıca 60 sn'de bir defadan fazla gösterilmez.
final class InterstitialManager: NSObject, FullScreenContentDelegate {
    static let shared = InterstitialManager()

    private var ad: InterstitialAd?
    private var isLoading = false
    private var lastShown = Date.distantPast
    /// Peş peşe reklamı engelleyen minimum ara.
    private let minInterval: TimeInterval = 60

    private override init() { super.init() }

    /// Bir sonraki reklamı önceden yükler (gösterime hazır olsun diye).
    func preload() {
        guard ad == nil, !isLoading else { return }
        isLoading = true
        InterstitialAd.load(with: AdConfig.interstitialID, request: Request()) { [weak self] loadedAd, _ in
            guard let self else { return }
            self.isLoading = false
            self.ad = loadedAd
            self.ad?.fullScreenContentDelegate = self
        }
    }

    /// Premium değilse, reklam hazırsa ve son gösterimden yeterince zaman geçtiyse gösterir.
    func maybeShow() {
        guard !UserDefaults.standard.bool(forKey: "premiumActive") else { return }
        guard Date().timeIntervalSince(lastShown) >= minInterval else { return }
        guard let ad, let root = Self.topViewController() else {
            preload()
            return
        }
        lastShown = Date()
        ad.present(from: root)
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        self.ad = nil
        preload()
        // Reklamdan sonra aralıklı olarak premium önerisi göster.
        Task { @MainActor in PromptCoordinator.shared.maybePrompt() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.ad = nil
        preload()
    }

    // MARK: - Yardımcı

    /// O an ekranda en üstte olan view controller'ı bulur (sheet açıksa onu).
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

/// Aralıklı premium önerisini (paywall) yönetir. Reklamdan sonra tetiklenir;
/// premium değilse ve son öneriden yeterince zaman geçtiyse gösterilir.
/// Kolayca kapatılabilir (paywall'da X + aşağı kaydırma).
@MainActor
final class PromptCoordinator: ObservableObject {
    static let shared = PromptCoordinator()

    @Published var showPremiumPrompt = false
    private var lastPrompt = Date.distantPast
    /// Aralıklı: en fazla 6 saatte bir öneri.
    private let minInterval: TimeInterval = 6 * 3600

    private init() {}

    func maybePrompt() {
        guard !UserDefaults.standard.bool(forKey: "premiumActive") else { return }
        guard Date().timeIntervalSince(lastPrompt) >= minInterval else { return }
        lastPrompt = Date()
        showPremiumPrompt = true
    }
}
