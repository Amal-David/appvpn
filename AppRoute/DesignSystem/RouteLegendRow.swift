import SwiftUI

struct RouteLegendRow: View {
    var title: String
    var detail: String
    var usesVPN: Bool

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(usesVPN ? AppTheme.vpn : AppTheme.direct)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(usesVPN ? "VPN" : "Direct")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(usesVPN ? AppTheme.vpn : AppTheme.direct)
        }
        .accessibilityElement(children: .combine)
    }
}
