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

    func add(
        title: String,
        notes: String,
        callerName: String,
        triggerDate: Date,
        mode: ReminderMode,
        audioFileName: String
    ) async throws {
        let reminder = ReminderItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            callerName: callerName.trimmingCharacters(in: .whitespacesAndNewlines),
            triggerDate: triggerDate,
            mode: mode,
            audioFileName: audioFileName
        )

        try await scheduler.schedule(reminder)
        reminders.append(reminder)
        sortReminders()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            let reminder = reminders[index]
            scheduler.remove(reminder)
            AudioFileStore.delete(fileName: reminder.audioFileName)
        }
        reminders.remove(atOffsets: offsets)
    }

    func complete(_ reminder: ReminderItem) {
        guard let index = reminders.firstIndex(of: reminder) else { return }
        reminders[index].isDone = true
        scheduler.remove(reminders[index])
        sortReminders()
    }

    func toggleDone(_ reminder: ReminderItem) {
        guard let index = reminders.firstIndex(of: reminder) else { return }
        reminders[index].isDone.toggle()

        if reminders[index].isDone {
            scheduler.remove(reminders[index])
        } else if reminders[index].triggerDate > Date() {
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
