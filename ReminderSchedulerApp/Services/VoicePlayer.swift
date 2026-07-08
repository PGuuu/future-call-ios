import AVFoundation
import Foundation

@MainActor
final class VoicePlayer: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    func play(fileName: String) {
        stop()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)

            let url = AudioFileStore.url(for: fileName)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
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

extension VoicePlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}

@MainActor
final class RingtonePlayer: ObservableObject {
    private var player: AVAudioPlayer?

    func startRinging() {
        guard player == nil else { return }
        guard let url = Bundle.main.url(forResource: "FutureCallRing", withExtension: "wav") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.play()
            player = newPlayer
        } catch {
            player = nil
        }
    }

    func stopRinging() {
        player?.stop()
        player = nil
    }
}
