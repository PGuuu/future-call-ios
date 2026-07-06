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
                    Text(hasAnswered ? "Connected" : "Incoming Future Call")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))

                    Text(reminder.callerName)
                        .font(.system(size: 44, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text(reminder.title)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.76))
                        .padding(.horizontal, 32)
                }

                if hasAnswered {
                    VStack(spacing: 14) {
                        Image(systemName: player.isPlaying ? "waveform.circle.fill" : "play.circle.fill")
                            .font(.system(size: 82))
                            .foregroundStyle(.white)

                        Button(player.isPlaying ? "Playing" : "Replay message") {
                            player.play(fileName: reminder.audioFileName)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(.black)
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
                        callButton(title: "Decline", icon: "phone.down.fill", color: .red) {
                            onDismiss()
                        }

                        callButton(title: "Accept", icon: "phone.fill", color: .green) {
                            hasAnswered = true
                            player.play(fileName: reminder.audioFileName)
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
}

#Preview {
    IncomingCallView(
        reminder: ReminderItem(
            title: "Remember why you started",
            notes: "",
            callerName: "Past Me",
            triggerDate: Date(),
            mode: .dateTime,
            audioFileName: "sample.m4a"
        ),
        onComplete: {},
        onDismiss: {}
    )
}
