import SwiftUI

struct ReminderRowView: View {
    let reminder: ReminderItem
    let onToggleDone: () -> Void

    var body: some View {
        Button(action: onToggleDone) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(reminder.title)
                            .font(.headline)
                            .strikethrough(reminder.isDone)
                            .foregroundStyle(.primary)

                        Spacer(minLength: 8)

                        Text(reminder.mode.title)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(.secondary)
                            .background(.quaternary, in: Capsule())
                    }

                    Text(reminder.callerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !reminder.notes.isEmpty {
                        Text(reminder.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Label {
                        Text(reminder.triggerDate, format: .dateTime.year().month().day().hour().minute())
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(reminder.isReadyToCall ? .green : .blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        if reminder.isDone {
            return "checkmark.circle.fill"
        }
        return reminder.isReadyToCall ? "phone.badge.waveform.fill" : "phone.badge.clock.fill"
    }

    private var iconColor: Color {
        if reminder.isDone {
            return .green
        }
        return reminder.isReadyToCall ? .green : .blue
    }
}

#Preview {
    ReminderRowView(
        reminder: ReminderItem(
            title: "A message from today",
            notes: "Listen when you need a reset.",
            callerName: "Past Me",
            triggerDate: Date().addingTimeInterval(600),
            mode: .timer,
            audioFileName: "sample.m4a"
        ),
        onToggleDone: {}
    )
    .padding()
}
