import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

/// Reklam yapılandırması.
enum AdConfig {
    /// AdMob panelinden alınan gerçek banner reklam birimi.
    static let realBannerID = "ca-app-pub-6959840143670078/9929508636"
    /// Google'ın resmi test banner birimi.
    static let testBannerID = "ca-app-pub-3940256099942544/2934735716"

    /// TestFlight (sandbox) veya geliştirmede test reklamı gösterilir; böylece
    /// kendi tıklamalarımız "geçersiz trafik" sayılmaz. Yalnızca App Store'dan
    /// indirilen sürümde gerçek reklam yayınlanır. Tek derleme her ikisini kapsar.
    static var isTestEnvironment: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    static var bannerID: String { isTestEnvironment ? testBannerID : realBannerID }
}

/// Uygulama açılışında reklam SDK'sını başlatır ve izleme iznini ister.
enum AdBootstrap {
    static func start() {
        MobileAds.shared.start(completionHandler: nil)
        // Kısa bir gecikmeyle izleme izni iste (açılış animasyonu bitsin)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { _ in }
            }
        }
    }
}

/// Ana ekranın altına yerleşen banner reklam.
struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdConfig.bannerID
        banner.rootViewController = Self.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    private static func rootViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        return scene?.keyWindow?.rootViewController
    }
}

/// Banner'ı standart yüksekliğinde saran, arkaplanla uyumlu kapsayıcı.
struct BannerContainer: View {
    var body: some View {
        AdBannerView()
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Palette.night)
    }
}
