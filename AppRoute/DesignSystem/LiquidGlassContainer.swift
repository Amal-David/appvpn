import SwiftUI

struct LiquidGlassContainer<Content: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder var content: () -> Content

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content()
        }
    }
}
