import SwiftUI

@main
struct ReminderSchedulerApp: App {
    @StateObject private var store = ReminderStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    await NotificationScheduler.shared.requestAuthorization()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                store.refreshExpiredReminders()
            }
        }
    }
}
