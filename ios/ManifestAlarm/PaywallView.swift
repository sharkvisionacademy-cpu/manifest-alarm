import SwiftUI
import StoreKit

/// Manifest Premium satın alma ekranı (paywall).
struct PaywallView: View {
    @ObservedObject var subs = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = SubscriptionManager.yearlyID

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://manifest-alarm.aether-proxy.workers.dev")!

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    benefits
                    plans
                    cta
                    legalRow
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .topTrailing) { closeButton }
        .tint(Palette.gold)
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(16)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(Palette.gold)
                .padding(.top, 30)
            Text("paywall_title")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
            Text("paywall_sub")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefitRow("checkmark.seal.fill", "benefit_noads")
            benefitRow("square.stack.3d.up.fill", "benefit_packs")
            benefitRow("paintpalette.fill", "benefit_future")
            benefitRow("heart.fill", "benefit_support")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
    }

    private func benefitRow(_ icon: String, _ key: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Palette.gold)
                .frame(width: 26)
            Text(key)
                .font(.callout)
                .foregroundStyle(.white)
        }
    }

    private var plans: some View {
        VStack(spacing: 12) {
            if subs.products.isEmpty {
                ProgressView().tint(Palette.gold).padding()
            } else {
                ForEach(subs.products, id: \.id) { product in
                    planCard(product)
                }
            }
        }
    }

    private func planCard(_ product: Product) -> some View {
        let selected = product.id == selectedID
        let best = product.id == SubscriptionManager.yearlyID
        return Button {
            selectedID = product.id
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Palette.gold : .white.opacity(0.4))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(planName(product))
                            .font(.headline)
                            .foregroundStyle(.white)
                        if best {
                            Text("best_value")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Palette.night)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Palette.gold))
                        }
                    }
                    Text(priceLine(product))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(Palette.gold)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? Palette.gold : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var cta: some View {
        VStack(spacing: 10) {
            Button {
                guard let product = subs.product(for: selectedID) else { return }
                Task { await subs.purchase(product) }
            } label: {
                Group {
                    if subs.isWorking {
                        ProgressView().tint(Palette.night)
                    } else {
                        Text(ctaTitle)
                            .font(.headline.weight(.bold))
                    }
                }
                .foregroundStyle(Palette.night)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.gold))
            }
            .disabled(subs.isWorking || subs.products.isEmpty)

            Text("auto_renew_note")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            if let error = subs.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var legalRow: some View {
        HStack(spacing: 18) {
            Button("restore_purchases") { Task { await subs.restore() } }
            Link("terms_of_use", destination: termsURL)
            Link("privacy_policy", destination: privacyURL)
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.55))
        .tint(.white.opacity(0.55))
    }

    // MARK: - Metin yardımcıları

    private var ctaTitle: LocalizedStringKey {
        // Seçilen planda deneme varsa "3 gün ücretsiz dene" göster.
        if let p = subs.product(for: selectedID), hasTrial(p) {
            return "trial_cta"
        }
        return "subscribe_cta"
    }

    private func hasTrial(_ product: Product) -> Bool {
        guard let offer = product.subscription?.introductoryOffer else { return false }
        return offer.paymentMode == .freeTrial
    }

    private func planName(_ product: Product) -> LocalizedStringKey {
        switch product.id {
        case SubscriptionManager.weeklyID:  return "plan_weekly"
        case SubscriptionManager.monthlyID: return "plan_monthly"
        case SubscriptionManager.yearlyID:  return "plan_yearly"
        default: return LocalizedStringKey(product.displayName)
        }
    }

    private func priceLine(_ product: Product) -> String {
        let price = product.displayPrice
        let per = periodText(product)
        if hasTrial(product) {
            return String(format: String(localized: "trial_price_line"), price, per)
        }
        return "\(price) / \(per)"
    }

    private func periodText(_ product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .week:  return String(localized: "per_week")
        case .month: return String(localized: "per_month")
        case .year:  return String(localized: "per_year")
        case .day:   return String(localized: "per_day")
        @unknown default: return ""
        }
    }
}
