import Foundation

@MainActor
final class ReminderStore: ObservableObject {
    @Published private(set) var reminders: [ReminderItem] = [] {
        didSet {
            save()
        }
    }

    private let storageKey = "saved-future-calls"
    private let scheduler = NotificationScheduler.shared

    init() {
        reminders = load()
        sortReminders()
    }

    var nextIncomingCall: ReminderItem? {
        reminders.first { $0.isReadyToCall }
    }

    var futureReminders: [ReminderItem] {
        reminders.filter { !$0.isDone }
    }

    var pastReminders: [ReminderItem] {
        reminders.filter { $0.isDone }
    }

    func reminder(id: UUID) -> ReminderItem? {
        reminders.first { $0.id == id }
    }

    func add(
        title: String,
        notes: String,
        triggerDate: Date,
        mode: ReminderMode,
        audioFileName: String?,
        repeatIntervalMinutes: Int?
    ) async throws {
        let reminder = ReminderItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            triggerDate: triggerDate,
            mode: mode,
            audioFileName: audioFileName,
            repeatIntervalMinutes: repeatIntervalMinutes
        )

        try await scheduler.schedule(reminder)
        reminders.append(reminder)
        sortReminders()
    }

    func update(_ reminder: ReminderItem) async throws {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        var updated = reminder
        updated.title = updated.title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = updated.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.callerName = "Past Me"
        updated.isDone = false

        scheduler.remove(reminders[index])
        try await scheduler.schedule(updated)
        reminders[index] = updated
        sortReminders()
    }

    func delete(_ reminder: ReminderItem) {
        scheduler.remove(reminder)
        if let audioFileName = reminder.audioFileName {
            AudioFileStore.delete(fileName: audioFileName)
        }
        reminders.removeAll { $0.id == reminder.id }
    }

    func complete(_ reminder: ReminderItem) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isDone = true
        scheduler.remove(reminders[index])
        sortReminders()
    }

    func toggleDone(_ reminder: ReminderItem) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isDone.toggle()

        if reminders[index].isDone {
            scheduler.remove(reminders[index])
        } else if reminders[index].triggerDate > Date() || reminders[index].mode == .repeating {
            let reminderToSchedule = reminders[index]
            Task {
                try? await scheduler.schedule(reminderToSchedule)
            }
        }

        sortReminders()
    }

    func refreshExpiredReminders() {
        sortReminders()
    }

    private func sortReminders() {
        reminders.sort {
            if $0.isDone != $1.isDone {
                return !$0.isDone
            }
            if $0.isDone {
                return $0.triggerDate > $1.triggerDate
            }
            return $0.triggerDate < $1.triggerDate
        }
    }

    private func load() -> [ReminderItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([ReminderItem].self, from: data)
        } catch {
            return []
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(reminders) else {
            return
        }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
