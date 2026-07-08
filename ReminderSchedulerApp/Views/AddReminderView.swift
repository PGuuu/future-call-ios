import SwiftUI
import UIKit

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
        case confirmation
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
    @State private var isRandomTime: Bool
    @State private var isTimeHidden: Bool
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
        _isRandomTime = State(initialValue: reminderToEdit?.randomTime ?? false)
        _isTimeHidden = State(initialValue: reminderToEdit?.timeHidden ?? false)
    }

    private var repeatIntervalMinutes: Int {
        (hours * 60) + minutes
    }

    private func resolvedTriggerDate() -> Date {
        switch mode {
        case .repeating:
            return Date().addingTimeInterval(TimeInterval(max(repeatIntervalMinutes, 1) * 60))
        case .dateTime:
            guard isRandomTime else { return selectedDate }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            components.hour = Int.random(in: 9...20)
            components.minute = Int.random(in: 0...59)
            let candidate = Calendar.current.date(from: components) ?? selectedDate

            if candidate <= Date() {
                return Date().addingTimeInterval(TimeInterval(Int.random(in: 15...120) * 60))
            }
            return candidate
        }
    }

    private var scheduledDateIsValid: Bool {
        if isRandomTime {
            let startOfDay = Calendar.current.startOfDay(for: selectedDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate
            return endOfDay > Date()
        }
        return selectedDate > Date()
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
            return scheduledDateIsValid
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
                case .confirmation:
                    confirmationStep
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if step != .confirmation {
                        Button("Cancel") {
                            recorder.stop()
                            dismiss()
                        }
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
        case .confirmation:
            return "Scheduled"
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

                if recorder.isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 108, height: 108)
                        .scaleEffect(1.0 + recorder.level * 0.6)
                        .animation(.easeOut(duration: 0.12), value: recorder.level)
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

            if recorder.isRecording {
                Text(String(format: "%02d:%02d", recorder.elapsedSeconds / 60, recorder.elapsedSeconds % 60))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

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
                    .disabled(mode == .dateTime && !scheduledDateIsValid)
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
                Toggle("Anytime that day", isOn: $isRandomTime)

                if isRandomTime {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                } else {
                    DatePicker(
                        "Date and time",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Toggle("Keep the time a secret", isOn: $isTimeHidden)

                if isTimeHidden || isRandomTime {
                    Text(isTimeHidden
                        ? "The call will show as \"someday\" until it rings."
                        : "Past Me will pick a moment on that day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

    private var confirmationStep: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: creationKind == .voice ? "phone.arrow.up.right.circle.fill" : "paperplane.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.green)

            Text(creationKind == .voice ? "Call scheduled" : "Message scheduled")
                .font(.title2.bold())

            Text(confirmationMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private var confirmationMessage: String {
        let action = creationKind == .voice ? "call" : "text"

        switch mode {
        case .repeating:
            return "Past Me will keep \(action == "call" ? "calling" : "texting") you every \(intervalText) until you pick up."
        case .dateTime:
            if isTimeHidden {
                return "Past Me will \(action) you someday. You won't see it coming."
            }
            if isRandomTime {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US")
                formatter.dateFormat = "MMM d"
                return "Past Me will \(action) you on \(formatter.string(from: selectedDate)), sometime that day."
            }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            formatter.locale = Locale(identifier: "en_US")
            let relative = formatter.localizedString(for: selectedDate, relativeTo: Date())
            return "Past Me will \(action) you \(relative)."
        }
    }

    private var intervalText: String {
        if hours > 0 && minutes > 0 {
            return "\(hours) hr \(minutes) min"
        }
        if hours > 0 {
            return "\(hours) hr"
        }
        return "\(minutes) min"
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
                let finalTriggerDate = resolvedTriggerDate()

                if var reminderToEdit {
                    reminderToEdit.title = title
                    reminderToEdit.notes = notes
                    reminderToEdit.mode = mode
                    reminderToEdit.triggerDate = finalTriggerDate
                    reminderToEdit.audioFileName = creationKind == .voice ? audioFileName : nil
                    reminderToEdit.repeatIntervalMinutes = mode == .repeating ? repeatIntervalMinutes : nil
                    reminderToEdit.isRandomTime = mode == .dateTime && isRandomTime
                    reminderToEdit.isTimeHidden = mode == .dateTime && isTimeHidden
                    try await store.update(reminderToEdit)
                } else {
                    try await store.add(
                        title: title,
                        notes: notes,
                        triggerDate: finalTriggerDate,
                        mode: mode,
                        audioFileName: creationKind == .voice ? audioFileName : nil,
                        repeatIntervalMinutes: mode == .repeating ? repeatIntervalMinutes : nil,
                        isRandomTime: mode == .dateTime && isRandomTime,
                        isTimeHidden: mode == .dateTime && isTimeHidden
                    )
                }

                if reminderToEdit == nil {
                    step = .confirmation
                } else {
                    dismiss()
                }
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
