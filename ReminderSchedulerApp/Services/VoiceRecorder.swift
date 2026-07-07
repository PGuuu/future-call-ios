import AVFoundation
import Foundation

@MainActor
final class VoiceRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var recordedFileName: String?

    private var recorder: AVAudioRecorder?

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
        newRecorder.record()
        recorder = newRecorder
        recordedFileName = fileName
        isRecording = true
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        isRecording = false
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
