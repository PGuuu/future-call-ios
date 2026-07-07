import SwiftUI

struct IncomingCallView: View {
    let reminder: ReminderItem
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @StateObject private var player = VoicePlayer()
    @State private var hasAnswered = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.1, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 10) {
                    Text(incomingLabel)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))

                    Text("Past Me")
                        .font(.system(size: 44, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text(displayTitle)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.76))
                        .padding(.horizontal, 32)
                }

                if hasAnswered {
                    VStack(spacing: 14) {
                        Image(systemName: reminder.hasVoiceMessage ? (player.isPlaying ? "waveform.circle.fill" : "play.circle.fill") : "text.bubble.fill")
                            .font(.system(size: 82))
                            .foregroundStyle(.white)

                        if let audioFileName = reminder.audioFileName {
                            Button(player.isPlaying ? "Playing" : "Replay message") {
                                player.play(fileName: audioFileName)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white)
                            .foregroundStyle(.black)
                        }

                        if !reminder.notes.isEmpty {
                            Text(reminder.notes)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.72))
                                .padding(.horizontal, 32)
                        }
                    }
                }

                Spacer()

                if hasAnswered {
                    Button {
                        player.stop()
                        onComplete()
                    } label: {
                        Label("End Call", systemImage: "phone.down.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 32)
                } else {
                    HStack(spacing: 54) {
                        callButton(title: "Later", icon: "phone.down.fill", color: .red) {
                            onDismiss()
                        }

                        callButton(title: reminder.hasVoiceMessage ? "Accept" : "Read", icon: reminder.hasVoiceMessage ? "phone.fill" : "message.fill", color: .green) {
                            hasAnswered = true
                            if let audioFileName = reminder.audioFileName {
                                player.play(fileName: audioFileName)
                            }
                        }
                    }
                    .padding(.bottom, 42)
                }
            }
        }
    }

    private func callButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 74, height: 74)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
    }

    private var displayTitle: String {
        if reminder.title.isEmpty {
            return reminder.hasVoiceMessage ? "A voice message is waiting" : "Reminder"
        }
        return reminder.title
    }

    private var incomingLabel: String {
        if hasAnswered {
            return reminder.hasVoiceMessage ? "Connected" : "Message"
        }
        return reminder.hasVoiceMessage ? "Incoming Future Call" : "Message from the past"
    }
}

#Preview {
    IncomingCallView(
        reminder: ReminderItem(
            title: "Remember why you started",
            notes: "",
            triggerDate: Date(),
            mode: .dateTime,
            audioFileName: "sample.m4a"
        ),
        onComplete: {},
        onDismiss: {}
    )
}
