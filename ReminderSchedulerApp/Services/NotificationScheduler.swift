import Foundation
import UserNotifications

extension Notification.Name {
    static let futureCallNotificationOpened = Notification.Name("futureCallNotificationOpened")
}

final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()

    private var pendingReminderID: UUID?

    private override init() {}

    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    func consumePendingReminderID() -> UUID? {
        let id = pendingReminderID
        pendingReminderID = nil
        return id
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        route(response.notification.request.content.userInfo)
        completionHandler()
    }

    private func route(_ userInfo: [AnyHashable: Any]) {
        guard let rawID = userInfo["reminderID"] as? String,
              let id = UUID(uuidString: rawID) else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.pendingReminderID = id
            NotificationCenter.default.post(name: .futureCallNotificationOpened, object: nil)
        }
    }
}

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
        content.title = reminder.hasVoiceMessage ? "Future Call" : "Future Message"
        content.subtitle = "Past Me"
        content.body = reminder.title.isEmpty ? "Past Me has something for you." : reminder.title
        content.sound = .default
        content.userInfo = ["reminderID": reminder.id.uuidString]

        let trigger: UNNotificationTrigger
        if reminder.mode == .repeating {
            let minutes = max(reminder.repeatIntervalMinutes ?? 5, 1)
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(minutes * 60),
                repeats: true
            )
        } else {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: reminder.triggerDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

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
