import AVFoundation
import Foundation

@MainActor
final class VoicePlayer: ObservableObject {
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    func play(fileName: String) {
        stop()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)

            let url = AudioFileStore.url(for: fileName)
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}
