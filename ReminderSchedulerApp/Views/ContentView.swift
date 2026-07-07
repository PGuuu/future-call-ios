import SwiftUI

enum ReminderListKind {
    case missed
    case future
    case past

    var title: String {
        switch self {
        case .missed:
            return "未接聽"
        case .future:
            return "未來通話"
        case .past:
            return "過往通話"
        }
    }

    var emptyTitle: String {
        switch self {
        case .missed:
            return "沒有未接聽"
        case .future:
            return "沒有未來通話"
        case .past:
            return "沒有過往通話"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @ObservedObject private var notificationRouter = NotificationRouter.shared
    @State private var isAddingReminder = false
    @State private var reminderToEdit: ReminderItem?
    @State private var activeReminder: ReminderItem?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isAddingReminder = true
                    } label: {
                        HomeActionRow(
                            title: "打給未來",
                            subtitle: "錄一段語音，或留一則簡訊給未來的自己",
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
                            title: "尚未接聽",
                            subtitle: "已經到時間，但還沒有接聽或閱讀",
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
                            title: "未來通話",
                            subtitle: "預定時間與持續提醒",
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
                            title: "過往通話",
                            subtitle: "已接聽或已閱讀的紀錄",
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
            .fullScreenCover(item: $activeReminder) { reminder in
                IncomingCallView(
                    reminder: reminder,
                    onComplete: {
                        store.complete(reminder)
                        activeReminder = nil
                    },
                    onDismiss: {
                        activeReminder = nil
                    }
                )
            }
            .onChange(of: notificationRouter.openedReminderID) {
                openReminderFromNotification()
            }
            .onAppear {
                openReminderFromNotification()
            }
        }
    }

    private func openReminderFromNotification() {
        guard let id = notificationRouter.openedReminderID else { return }

        guard let reminder = store.reminder(id: id),
              !reminder.isDone else {
            DispatchQueue.main.async {
                notificationRouter.openedReminderID = nil
            }
            return
        }

        DispatchQueue.main.async {
            notificationRouter.openedReminderID = nil
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
