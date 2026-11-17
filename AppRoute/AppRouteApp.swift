import SwiftUI

@main
struct AppRouteApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .tint(AppTheme.vpn)
                .task {
                    await session.bootstrap()
                }
        }
    }
}
