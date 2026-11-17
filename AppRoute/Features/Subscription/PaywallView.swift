import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "AppRoute Pro",
                    title: "Keep compatibility free. Unlock routing.",
                    subtitle: "The compatibility checker stays free. Pro adds Smart Routing, service rules, and diagnostics. 7-day trial, then $3.99/month or $29.99/year."
                )

                if session.subscriptionStore.isPro {
                    TrustPanel(
                        title: "Pro is active",
                        bodyText: "Thank you. You can restore purchases on any device signed into the same Apple Account.",
                        systemImage: "checkmark.seal"
                    )
                }

                if let error = session.subscriptionStore.loadError {
                    Text(AppRouteError.subscriptionUnavailable(error).userFacingMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(session.subscriptionStore.products, id: \.id) { product in
                    Button {
                        Task { await buy(product) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.displayName)
                                    .font(.headline)
                                Text(product.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(product.displayPrice)
                                .font(.headline)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }

                if session.subscriptionStore.products.isEmpty && session.subscriptionStore.isLoading == false {
                    Text("StoreKit products are not in App Store Connect yet. Use the bundled StoreKit configuration when running from Xcode.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button("Restore purchases") {
                    Task { await session.subscriptionStore.restore() }
                }
                .buttonStyle(.glass)
            }
            .padding(24)
        }
        .navigationTitle("Pro")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.subscriptionStore.loadProducts()
        }
    }

    private func buy(_ product: Product) async {
        await session.subscriptionStore.purchase(product)
        if session.subscriptionStore.isPro {
            session.record(.subscriptionStarted)
        }
    }
}
