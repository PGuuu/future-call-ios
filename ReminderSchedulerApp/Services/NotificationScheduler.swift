import Foundation
import UserNotifications

enum ReminderError: LocalizedError {
    case dateInPast
    case notificationPermissionDenied

    var errorDescription: String? {
        switch self {
        case .dateInPast:
            return "The call time must be in the future."
        case .notificationPermissionDenied:
            return "Turn on notifications in Settings to receive future calls."
        }
    }
}

final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            // The app can still save capsules even when the system prompt fails.
        }
    }

    func schedule(_ reminder: ReminderItem) async throws {
        guard reminder.triggerDate > Date() else {
            throw ReminderError.dateInPast
        }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else {
            throw ReminderError.notificationPermissionDenied
        }

        center.removePendingNotificationRequests(withIdentifiers: [reminder.notificationIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Future Call"
        content.subtitle = reminder.callerName
        content.body = reminder.title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminder.triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminder.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    private func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            await requestAuthorization()
            return await center.notificationSettings().authorizationStatus
        }

        return settings.authorizationStatus
    }

    func remove(_ reminder: ReminderItem) {
        center.removePendingNotificationRequests(withIdentifiers: [reminder.notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [reminder.notificationIdentifier])
    }
}
