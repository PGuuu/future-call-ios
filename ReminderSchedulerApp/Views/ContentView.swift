import SwiftUI

enum ReminderListKind {
    case missed
    case future
    case past

    var title: String {
        switch self {
        case .missed:
            return "Missed"
        case .future:
            return "Future"
        case .past:
            return "Past"
        }
    }

    var emptyTitle: String {
        switch self {
        case .missed:
            return "No missed calls"
        case .future:
            return "No future calls"
        case .past:
            return "No past calls"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @State private var isAddingReminder = false
    @State private var reminderToEdit: ReminderItem?
    @State private var activeReminder: ReminderItem?

    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    Section {
                        Button {
                            isAddingReminder = true
                        } label: {
                            HomeActionRow(
                                title: "Call the Future",
                                subtitle: "Record a voice call or write a message to your future self",
                                icon: "plus.message.fill",
                                color: .blue,
                                count: nil
                            )
                        }

                        NavigationLink {
                            ReminderListView(
                                kind: .missed,
                                reminders: store.missedReminders,
                                onSelect: { activeReminder = $0 },
                                onEdit: { reminderToEdit = $0 },
                                onDelete: store.delete
                            )
                        } label: {
                            HomeActionRow(
                                title: "Not Answered",
                                subtitle: "Calls and messages that are ready but unread",
                                icon: "phone.badge.waveform.fill",
                                color: .orange,
                                count: store.missedReminders.count
                            )
                        }

                        NavigationLink {
                            ReminderListView(
                                kind: .future,
                                reminders: store.futureReminders,
                                onSelect: { reminderToEdit = $0 },
                                onEdit: { reminderToEdit = $0 },
                                onDelete: store.delete
                            )
                        } label: {
                            HomeActionRow(
                                title: "Future Calls",
                                subtitle: "Scheduled calls, messages, and keep-reminding alerts",
                                icon: "calendar.badge.clock",
                                color: .green,
                                count: store.futureReminders.count
                            )
                        }

                        NavigationLink {
                            ReminderListView(
                                kind: .past,
                                reminders: store.pastReminders,
                                onSelect: { _ in },
                                onEdit: { _ in },
                                onDelete: store.delete
                            )
                        } label: {
                            HomeActionRow(
                                title: "Past Calls",
                                subtitle: "Calls and messages already answered or read",
                                icon: "clock.arrow.circlepath",
                                color: .gray,
                                count: store.pastReminders.count
                            )
                        }
                    }
                }
                .navigationTitle("Future Call")
                .sheet(isPresented: $isAddingReminder) {
                    AddReminderView()
                        .environmentObject(store)
                }
                .sheet(item: $reminderToEdit) { reminder in
                    AddReminderView(reminderToEdit: reminder)
                        .environmentObject(store)
                }
                .onReceive(NotificationCenter.default.publisher(for: .futureCallNotificationOpened)) { _ in
                    openReminderFromNotification()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        openReminderFromNotification()
                    }
                }
            }

            if let presentedReminder = activeReminder {
                IncomingCallView(
                    reminder: presentedReminder,
                    onComplete: {
                        store.complete(presentedReminder)
                        activeReminder = nil
                    },
                    onDismiss: {
                        activeReminder = nil
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    private func openReminderFromNotification() {
        guard let id = NotificationRouter.shared.consumePendingReminderID(),
              let reminder = store.reminder(id: id),
              !reminder.isDone else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            activeReminder = reminder
        }
    }
}

struct HomeActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let count: Int?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.16))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if let count {
                Text("\(count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ReminderListView: View {
    let kind: ReminderListKind
    let reminders: [ReminderItem]
    let onSelect: (ReminderItem) -> Void
    let onEdit: (ReminderItem) -> Void
    let onDelete: (ReminderItem) -> Void

    var body: some View {
        Group {
            if reminders.isEmpty {
                ContentUnavailableView(kind.emptyTitle, systemImage: "tray")
            } else {
                List {
                    ForEach(reminders) { reminder in
                        ReminderRowView(reminder: reminder)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(reminder)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    onDelete(reminder)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                if kind != .past {
                                    Button {
                                        onEdit(reminder)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(kind.title)
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderStore())
}
