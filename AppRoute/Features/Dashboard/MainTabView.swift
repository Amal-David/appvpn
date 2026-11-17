import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "point.3.connected.trianglepath.dotted") {
                DashboardView()
            }
            Tab("Services", systemImage: "square.grid.2x2") {
                NavigationStack {
                    ServicePickerView()
                }
            }
            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsRootView()
                }
            }
        }
    }
}
