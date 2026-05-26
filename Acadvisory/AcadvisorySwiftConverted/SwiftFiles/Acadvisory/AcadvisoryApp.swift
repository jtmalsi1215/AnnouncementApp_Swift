import SwiftUI
import FirebaseCore

@main
struct AcadvisoryApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootLauncherView()
        }
    }
}

struct RootLauncherView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var announcementStore = AnnouncementStore()

    var body: some View {
        ContentView()
            .environmentObject(authService)
            .environmentObject(announcementStore)
    }
}
