import Foundation

enum ReminderMode: String, Codable, CaseIterable, Identifiable {
    case timer
    case dateTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timer:
            return "Timer"
        case .dateTime:
            return "Date"
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
    var audioFileName: String
    var createdAt: Date
    var isDone: Bool

    var notificationIdentifier: String {
        "future-call-\(id.uuidString)"
    }

    var isReadyToCall: Bool {
        triggerDate <= Date() && !isDone
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String,
        callerName: String,
        triggerDate: Date,
        mode: ReminderMode,
        audioFileName: String,
        createdAt: Date = Date(),
        isDone: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.callerName = callerName
        self.triggerDate = triggerDate
        self.mode = mode
        self.audioFileName = audioFileName
        self.createdAt = createdAt
        self.isDone = isDone
    }
}
