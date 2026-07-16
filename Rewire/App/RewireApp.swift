import SwiftUI

@main
struct RewireApp: App {
    @State private var store = PathwayStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .preferredColorScheme(.dark)
                // Warm up the haptic engine before the first tap needs it.
                .task { _ = Haptics.shared }
        }
    }
}
