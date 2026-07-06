import SwiftUI

struct AddReminderView: View {
    @EnvironmentObject private var store: ReminderStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var recorder = VoiceRecorder()

    @State private var title = ""
    @State private var notes = ""
    @State private var callerName = "Past Me"
    @State private var mode: ReminderMode = .dateTime
    @State private var selectedDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
    @State private var hours = 0
    @State private var minutes = 10
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var isSaving = false

    private var timerDuration: TimeInterval {
        TimeInterval((hours * 60 + minutes) * 60)
    }

    private var triggerDate: Date {
        switch mode {
        case .timer:
            return Date().addingTimeInterval(timerDuration)
        case .dateTime:
            return selectedDate
        }
    }

    private var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaller = callerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedCaller.isEmpty, recorder.recordedFileName != nil, !isSaving else {
            return false
        }

        switch mode {
        case .timer:
            return timerDuration >= 60
        case .dateTime:
            return selectedDate > Date()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Call") {
                    TextField("Title", text: $title)
                    TextField("Caller name", text: $callerName)
                    TextField("Note", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section("Voice capsule") {
                    Button {
                        toggleRecording()
                    } label: {
                        Label(
                            recorder.isRecording ? "Stop recording" : "Record message",
                            systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                        )
                    }
                    .foregroundStyle(recorder.isRecording ? .red : .blue)

                    if recorder.recordedFileName != nil {
                        Label("Voice message saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section("Schedule") {
                    Picker("Mode", selection: $mode) {
                        ForEach(ReminderMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if mode == .dateTime {
                        DatePicker(
                            "Date and time",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        Stepper(value: $hours, in: 0...23) {
                            HStack {
                                Text("Hours")
                                Spacer()
                                Text("\(hours)")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Stepper(value: $minutes, in: 0...59) {
                            HStack {
                                Text("Minutes")
                                Spacer()
                                Text("\(minutes)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "phone.badge.waveform")
                            .foregroundStyle(.blue)
                        Text(triggerDate, format: .dateTime.year().month().day().hour().minute())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Future Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.stop()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving" : "Save") {
                        saveReminder()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Could not save", isPresented: $isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stop()
        } else {
            Task {
                do {
                    try await recorder.start()
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }

    private func saveReminder() {
        guard let audioFileName = recorder.recordedFileName else { return }
        recorder.stop()
        isSaving = true

        Task {
            do {
                try await store.add(
                    title: title,
                    notes: notes,
                    callerName: callerName,
                    triggerDate: triggerDate,
                    mode: mode,
                    audioFileName: audioFileName
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }

            isSaving = false
        }
    }
}

#Preview {
    AddReminderView()
        .environmentObject(ReminderStore())
}
