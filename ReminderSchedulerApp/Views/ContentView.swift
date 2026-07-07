import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @ObservedObject private var notificationRouter = NotificationRouter.shared
    @State private var isAddingReminder = false
    @State private var reminderToEdit: ReminderItem?
    @State private var activeCall: ReminderItem?
    @State private var snoozedReminderIDs: [UUID: Date] = [:]

    var body: some View {
        NavigationStack {
            Group {
                if store.reminders.isEmpty {
                    ContentUnavailableView(
                        "No future calls",
                        systemImage: "phone.down.waves.left.and.right",
                        description: Text("Record a call or write a message for your future self.")
                    )
                } else {
                    List {
                        if !store.futureReminders.isEmpty {
                            Section("Future") {
                                ForEach(store.futureReminders) { reminder in
                                    ReminderRowView(reminder: reminder)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            reminderToEdit = reminder
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                store.delete(reminder)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }

                        if !store.pastReminders.isEmpty {
                            Section("Past") {
                                ForEach(store.pastReminders) { reminder in
                                    ReminderRowView(reminder: reminder)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                store.delete(reminder)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Future Call")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingReminder = true
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingReminder) {
                AddReminderView()
                    .environmentObject(store)
            }
            .sheet(item: $reminderToEdit) { reminder in
                AddReminderView(reminderToEdit: reminder)
                    .environmentObject(store)
            }
            .fullScreenCover(item: $activeCall) { reminder in
                IncomingCallView(
                    reminder: reminder,
                    onComplete: {
                        store.complete(reminder)
                        activeCall = nil
                    },
                    onDismiss: {
                        snoozedReminderIDs[reminder.id] = Date().addingTimeInterval(60)
                        activeCall = nil
                    }
                )
            }
            .onAppear(perform: showIncomingCallIfNeeded)
            .onChange(of: store.reminders) {
                showIncomingCallIfNeeded()
            }
            .onChange(of: notificationRouter.openedReminderID) {
                openReminderFromNotification()
            }
        }
    }

    private func showIncomingCallIfNeeded() {
        guard activeCall == nil else { return }
        activeCall = store.futureReminders.first { reminder in
            guard reminder.isReadyToCall else { return false }
            if let snoozedUntil = snoozedReminderIDs[reminder.id], snoozedUntil > Date() {
                return false
            }
            return true
        }
    }

    private func openReminderFromNotification() {
        guard let id = notificationRouter.openedReminderID,
              let reminder = store.reminder(id: id),
              !reminder.isDone else {
            return
        }

        snoozedReminderIDs[id] = nil
        activeCall = reminder
        notificationRouter.openedReminderID = nil
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderStore())
}
