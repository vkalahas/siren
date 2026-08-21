import AVFoundation
import Foundation

/// Loops alarm audio while a mission session is active so sound continues after the system UI is dismissed.
@MainActor
final class AlarmRinger {
    static let shared = AlarmRinger()

    private var player: AVAudioPlayer?
    private var isPlaying = false

    private init() {}

    func start() {
        guard !isPlaying else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)

            guard let url = Bundle.main.url(forResource: "alarm_loop", withExtension: "caf")
                ?? Bundle.main.url(forResource: "alarm_loop", withExtension: "wav") else {
                print("AlarmRinger: no bundled alarm_loop audio file")
                return
            }

            let alarmPlayer = try AVAudioPlayer(contentsOf: url)
            alarmPlayer.numberOfLoops = -1
            alarmPlayer.prepareToPlay()
            alarmPlayer.play()

            player = alarmPlayer
            isPlaying = true
        } catch {
            print("AlarmRinger failed to start: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("AlarmRinger failed to deactivate session: \(error)")
        }
    }
}
