import SwiftUI

struct AddReminderView: View {
    enum Step {
        case voice
        case schedule
        case details
    }

    @EnvironmentObject private var store: ReminderStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    let reminderToEdit: ReminderItem?

    @StateObject private var recorder = VoiceRecorder()

    @State private var step: Step
    @State private var title: String
    @State private var notes: String
    @State private var mode: ReminderMode
    @State private var selectedDate: Date
    @State private var hours: Int
    @State private var minutes: Int
    @State private var existingAudioFileName: String?
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var isSaving = false

    private enum Field {
        case title
        case notes
    }

    init(reminderToEdit: ReminderItem? = nil) {
        self.reminderToEdit = reminderToEdit
        _step = State(initialValue: reminderToEdit == nil ? .voice : .details)
        _title = State(initialValue: reminderToEdit?.title ?? "")
        _notes = State(initialValue: reminderToEdit?.notes ?? "")
        _mode = State(initialValue: reminderToEdit?.mode ?? .dateTime)
        _selectedDate = State(initialValue: reminderToEdit?.triggerDate ?? Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date())
        let interval = reminderToEdit?.repeatIntervalMinutes ?? 10
        _hours = State(initialValue: interval / 60)
        _minutes = State(initialValue: max(interval % 60, reminderToEdit?.mode == .repeating ? 0 : 10))
        _existingAudioFileName = State(initialValue: reminderToEdit?.audioFileName)
    }

    private var repeatIntervalMinutes: Int {
        max((hours * 60) + minutes, 1)
    }

    private var triggerDate: Date {
        switch mode {
        case .repeating:
            return Date().addingTimeInterval(TimeInterval(repeatIntervalMinutes * 60))
        case .dateTime:
            return selectedDate
        }
    }

    private var audioFileName: String? {
        recorder.recordedFileName ?? existingAudioFileName
    }

    private var canSaveDetails: Bool {
        let hasText = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasVoice = audioFileName != nil
        guard (hasText || hasVoice), !isSaving else { return false }

        switch mode {
        case .repeating:
            return repeatIntervalMinutes >= 1
        case .dateTime:
            return selectedDate > Date()
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .voice:
                    voiceStep
                case .schedule:
                    scheduleStep
                case .details:
                    detailsStep
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.stop()
                        dismiss()
                    }
                }

                if step == .details {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(isSaving ? "Saving" : "Save") {
                            saveReminder()
                        }
                        .disabled(!canSaveDetails)
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Could not save", isPresented: $isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var navigationTitle: String {
        if reminderToEdit != nil { return "Edit Future Call" }

        switch step {
        case .voice:
            return "What do you want to say?"
        case .schedule:
            return "When should it call?"
        case .details:
            return "Add a title"
        }
    }

    private var voiceStep: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: recorder.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                .font(.system(size: 92))
                .foregroundStyle(recorder.isRecording ? .red : .blue)

            VStack(spacing: 8) {
                Text(recorder.isRecording ? "Recording..." : "Record a message")
                    .font(.title2.bold())
                Text("Skip recording to send it as a message from Past Me.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Button {
                toggleRecording()
            } label: {
                Label(recorder.isRecording ? "Stop Recording" : "Start Recording", systemImage: recorder.isRecording ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(recorder.isRecording ? .red : .blue)
            .padding(.horizontal, 32)

            if recorder.recordedFileName != nil {
                Button("Use this recording") {
                    step = .schedule
                }
                .buttonStyle(.bordered)
            }

            Button("Send as message") {
                recorder.stop()
                step = .schedule
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private var scheduleStep: some View {
        Form {
            Section {
                Button {
                    mode = .repeating
                    step = .details
                } label: {
                    Label("Constantly alert", systemImage: "repeat")
                }

                Button {
                    mode = .dateTime
                    step = .details
                } label: {
                    Label("Set a date and time", systemImage: "calendar.badge.clock")
                }
            }
        }
    }

    private var detailsStep: some View {
        Form {
            Section("Title and note") {
                TextField(audioFileName == nil ? "Title, e.g. Drink water" : "Title (optional)", text: $title)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.done)
                TextField("Note (optional)", text: $notes, axis: .vertical)
                    .focused($focusedField, equals: .notes)
                    .lineLimit(3, reservesSpace: true)
                    .submitLabel(.done)
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
                            Text("Every")
                            Spacer()
                            Text("\(hours) hr")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Stepper(value: $minutes, in: 0...59) {
                        HStack {
                            Text("Minutes")
                            Spacer()
                            Text("\(minutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Label(audioFileName == nil ? "Future Message" : "Future Call", systemImage: audioFileName == nil ? "message" : "waveform")
                    .foregroundStyle(.secondary)
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
        recorder.stop()
        isSaving = true

        Task {
            do {
                if var reminderToEdit {
                    reminderToEdit.title = title
                    reminderToEdit.notes = notes
                    reminderToEdit.mode = mode
                    reminderToEdit.triggerDate = triggerDate
                    reminderToEdit.audioFileName = audioFileName
                    reminderToEdit.repeatIntervalMinutes = mode == .repeating ? repeatIntervalMinutes : nil
                    try await store.update(reminderToEdit)
                } else {
                    try await store.add(
                        title: title,
                        notes: notes,
                        triggerDate: triggerDate,
                        mode: mode,
                        audioFileName: audioFileName,
                        repeatIntervalMinutes: mode == .repeating ? repeatIntervalMinutes : nil
                    )
                }
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
