import AudioToolbox
import AVFoundation
import Foundation

@MainActor
final class VoiceRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var recordedFileName: String?
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var level: Double = 0

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?

    func start() async throws {
        let granted = await requestPermission()
        guard granted else {
            throw RecordingError.microphoneDenied
        }

        let fileName = AudioFileStore.newFileName()
        let url = AudioFileStore.url(for: fileName)

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let newRecorder = try AVAudioRecorder(url: url, settings: settings)
        newRecorder.isMeteringEnabled = true

        // Voicemail-style beep, then start recording after it finishes.
        AudioServicesPlaySystemSound(1113)
        try? await Task.sleep(nanoseconds: 350_000_000)

        newRecorder.record()
        recorder = newRecorder
        recordedFileName = fileName
        isRecording = true
        startMetering()
    }

    func stop() {
        let wasRecording = isRecording
        recorder?.stop()
        recorder = nil
        isRecording = false
        stopMetering()

        if wasRecording {
            AudioServicesPlaySystemSound(1114)
        }
    }

    private func startMetering() {
        elapsedSeconds = 0
        level = 0
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMeter()
            }
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
        level = 0
    }

    private func updateMeter() {
        guard let recorder else { return }
        recorder.updateMeters()
        let power = Double(recorder.averagePower(forChannel: 0))
        level = max(0, min(1, (power + 50) / 50))
        elapsedSeconds = Int(recorder.currentTime)
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

enum RecordingError: LocalizedError {
    case microphoneDenied

    var errorDescription: String? {
        "Turn on microphone access in Settings to record a future call."
    }
}
