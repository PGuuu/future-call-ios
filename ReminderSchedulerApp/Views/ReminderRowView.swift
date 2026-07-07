import SwiftUI

struct ReminderRowView: View {
    let reminder: ReminderItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(displayTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Text(reminder.mode.title)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.secondary)
                        .background(.quaternary, in: Capsule())
                }

                Label(reminder.hasVoiceMessage ? "Voice from Past Me" : "Past Me", systemImage: reminder.hasVoiceMessage ? "waveform" : "text.bubble")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !reminder.notes.isEmpty {
                    Text(reminder.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Label {
                    Text(timeText)
                } icon: {
                    Image(systemName: reminder.mode == .repeating ? "repeat" : "clock")
                }
                .font(.caption)
                .foregroundStyle(reminder.isReadyToCall ? .green : .blue)
            }
        }
        .contentShape(Rectangle())
    }

    private var displayTitle: String {
        if reminder.title.isEmpty {
            return reminder.hasVoiceMessage ? "Voice message" : "Untitled"
        }
        return reminder.title
    }

    private var timeText: String {
        if reminder.mode == .repeating {
            let minutes = reminder.repeatIntervalMinutes ?? 0
            if minutes >= 60 && minutes % 60 == 0 {
                return "Every \(minutes / 60) hr"
            }
            return "Every \(minutes) min"
        }
        return reminder.triggerDate.formatted(date: .abbreviated, time: .shortened)
    }

    private var iconName: String {
        if reminder.isDone {
            return "phone.down.circle.fill"
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
            triggerDate: Date().addingTimeInterval(600),
            mode: .repeating,
            audioFileName: "sample.m4a"
        )
    )
    .padding()
}
