import SwiftUI

struct AddReminderView: View {
    private enum CreationKind {
        case voice
        case message
    }

    private enum Step {
        case chooseKind
        case recordVoice
        case messageDetails
        case schedule
        case finalDetails
    }

    @EnvironmentObject private var store: ReminderStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    let reminderToEdit: ReminderItem?

    @StateObject private var recorder = VoiceRecorder()

    @State private var step: Step
    @State private var creationKind: CreationKind
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
        let isEditing = reminderToEdit != nil
        _step = State(initialValue: isEditing ? .messageDetails : .chooseKind)
        _creationKind = State(initialValue: reminderToEdit?.hasVoiceMessage == true ? .voice : .message)
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
        (hours * 60) + minutes
    }

    private var triggerDate: Date {
        switch mode {
        case .repeating:
            return Date().addingTimeInterval(TimeInterval(max(repeatIntervalMinutes, 1) * 60))
        case .dateTime:
            return selectedDate
        }
    }

    private var audioFileName: String? {
        recorder.recordedFileName ?? existingAudioFileName
    }

    private var canSave: Bool {
        guard !isSaving else { return false }

        if creationKind == .voice && audioFileName == nil {
            return false
        }

        if creationKind == .message && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }

        switch mode {
        case .repeating:
            return repeatIntervalMinutes > 0
        case .dateTime:
            return selectedDate > Date()
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .chooseKind:
                    chooseKindStep
                case .recordVoice:
                    recordVoiceStep
                case .messageDetails:
                    detailsStep(nextTitle: reminderToEdit == nil ? "Next" : nil)
                case .schedule:
                    scheduleStep
                case .finalDetails:
                    detailsStep(nextTitle: nil)
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
        if reminderToEdit != nil { return "Edit" }

        switch step {
        case .chooseKind:
            return "打給未來"
        case .recordVoice:
            return "Record Voice"
        case .messageDetails:
            return "Title and Note"
        case .schedule:
            return "When?"
        case .finalDetails:
            return "Add a note"
        }
    }

    private var chooseKindStep: some View {
        List {
            Section {
                Button {
                    creationKind = .voice
                    step = .recordVoice
                } label: {
                    Label("語音", systemImage: "mic.circle.fill")
                }

                Button {
                    creationKind = .message
                    existingAudioFileName = nil
                    step = .messageDetails
                } label: {
                    Label("簡訊", systemImage: "message.circle.fill")
                }
            }
        }
    }

    private var recordVoiceStep: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(recorder.isRecording ? Color.red.opacity(0.35) : Color.blue.opacity(0.16), lineWidth: 2)
                        .frame(width: CGFloat(112 + index * 34), height: CGFloat(112 + index * 34))
                        .scaleEffect(recorder.isRecording ? 1.08 : 0.92)
                        .animation(
                            recorder.isRecording
                                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(index) * 0.16)
                                : .default,
                            value: recorder.isRecording
                        )
                }

                Image(systemName: recorder.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(recorder.isRecording ? .red : .blue)
                    .symbolEffect(.pulse, options: .repeating, value: recorder.isRecording)
            }
            .frame(height: 220)

            Text(recorder.isRecording ? "Recording..." : recordedText)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Button {
                toggleRecording()
            } label: {
                Label(recorder.isRecording ? "Stop Recording" : "Start Recording", systemImage: recorder.isRecording ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(recorder.isRecording ? .red : .blue)
            .padding(.horizontal, 32)

            Button("Save Voice") {
                recorder.stop()
                step = .schedule
            }
            .buttonStyle(.bordered)
            .disabled(audioFileName == nil)

            Spacer()
        }
    }

    private var recordedText: String {
        audioFileName == nil ? "Say something to your future self." : "Voice saved."
    }

    private var scheduleStep: some View {
        Form {
            Section("Reminder") {
                Picker("Mode", selection: $mode) {
                    Text("Keep Reminding").tag(ReminderMode.repeating)
                    Text("Schedule a Time").tag(ReminderMode.dateTime)
                }
                .pickerStyle(.segmented)

                scheduleControls
            }

            Section {
                if creationKind == .voice {
                    Button("Next") {
                        step = .finalDetails
                    }
                    .disabled(mode == .dateTime && selectedDate <= Date())
                } else {
                    Button(isSaving ? "Saving" : "Save") {
                        saveReminder()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func detailsStep(nextTitle: String?) -> some View {
        Form {
            Section("Title and note") {
                TextField(creationKind == .voice ? "Title (optional)" : "Title, e.g. Drink water", text: $title)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.done)

                TextField("Note (optional)", text: $notes, axis: .vertical)
                    .focused($focusedField, equals: .notes)
                    .lineLimit(3, reservesSpace: true)
                    .submitLabel(.done)
            }

            if reminderToEdit != nil {
                Section("Schedule") {
                    Picker("Mode", selection: $mode) {
                        Text("Keep Reminding").tag(ReminderMode.repeating)
                        Text("Schedule a Time").tag(ReminderMode.dateTime)
                    }
                    .pickerStyle(.segmented)

                    scheduleControls
                }
            }

            Section {
                if let nextTitle {
                    Button(nextTitle) {
                        step = .schedule
                    }
                    .disabled(creationKind == .message && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    Button(isSaving ? "Saving" : "Save") {
                        saveReminder()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var scheduleControls: some View {
        Group {
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
                    reminderToEdit.audioFileName = creationKind == .voice ? audioFileName : nil
                    reminderToEdit.repeatIntervalMinutes = mode == .repeating ? repeatIntervalMinutes : nil
                    try await store.update(reminderToEdit)
                } else {
                    try await store.add(
                        title: title,
                        notes: notes,
                        triggerDate: triggerDate,
                        mode: mode,
                        audioFileName: creationKind == .voice ? audioFileName : nil,
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
