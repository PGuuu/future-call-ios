import Foundation

enum ReminderMode: String, Codable, CaseIterable, Identifiable {
    case repeating = "timer"
    case dateTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .repeating:
            return "Constantly"
        case .dateTime:
            return "Once"
        }
    }
}

struct ReminderItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var notes: String
    var callerName: String
    var triggerDate: Date
    var mode: ReminderMode
    var audioFileName: String?
    var repeatIntervalMinutes: Int?
    var createdAt: Date
    var isDone: Bool

    var notificationIdentifier: String {
        "future-call-\(id.uuidString)"
    }

    var isReadyToCall: Bool {
        triggerDate <= Date() && !isDone
    }

    var hasVoiceMessage: Bool {
        audioFileName != nil
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String,
        callerName: String = "Past Me",
        triggerDate: Date,
        mode: ReminderMode,
        audioFileName: String? = nil,
        repeatIntervalMinutes: Int? = nil,
        createdAt: Date = Date(),
        isDone: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.callerName = "Past Me"
        self.triggerDate = triggerDate
        self.mode = mode
        self.audioFileName = audioFileName
        self.repeatIntervalMinutes = repeatIntervalMinutes
        self.createdAt = createdAt
        self.isDone = isDone
    }
}
