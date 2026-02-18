import AVFoundation
import Foundation

enum SoundEffect: Hashable {
    case correct
    case incorrect

    var filename: String {
        switch self {
        case .correct:
            "o.m4a"
        case .incorrect:
            "x.wav"
        }
    }
}

final class AudioService {
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    init() {
        preload(.correct)
        preload(.incorrect)
    }

    func play(_ effect: SoundEffect, muted: Bool) {
        guard !muted else {
            return
        }

        guard let player = players[effect] else {
            return
        }

        player.currentTime = 0
        player.play()
    }

    private func preload(_ effect: SoundEffect) {
        guard let url = Bundle.module.url(forResource: effect.filename, withExtension: nil, subdirectory: "audio") else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[effect] = player
        } catch {
            return
        }
    }
}
