import Foundation
import AVFoundation
import Combine
import Observation

@Observable
class AudioRecorder: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var isRecording = false
    var timerString = "00:00"

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var startTime: Date?
    private var completion: ((Bool) -> Void)?

    @MainActor
    func startRecording(to url: URL, completion: @escaping (Bool) -> Void) {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            self.completion = completion

            startTime = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in
                    let duration = Date().timeIntervalSince(self.startTime ?? Date())
                    let m = Int(duration) / 60
                    let s = Int(duration) % 60
                    self.timerString = String(format: "%02d:%02d", m, s)
                }
            }
        } catch {
            print("Recording failed: \(error)")
        }
    }

    @MainActor
    func stopRecording() {
        recorder?.stop()
        isRecording = false
        timer?.invalidate()
        timerString = "00:00"
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            completion?(flag)
        }
    }

    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
        } catch {
            print("Playback failed: \(error)")
        }
    }
}
