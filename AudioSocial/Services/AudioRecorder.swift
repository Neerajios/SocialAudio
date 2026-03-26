import Foundation
import AVFoundation
import Combine

enum RecorderState: Equatable {
    case idle
    case recording(elapsed: TimeInterval)
    case finished(fileURL: URL, duration: TimeInterval)
    case error(String)
}

final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var state: RecorderState = .idle
    @Published private(set) var remaining: TimeInterval = 30

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private let maxDuration: TimeInterval = 30
    private let sessionManager: AudioSessionManager

    init(sessionManager: AudioSessionManager) {
        self.sessionManager = sessionManager
    }

    func start() throws {
        guard case .granted = sessionManager.micStatus else {
            state = .error("Microphone permission not granted.")
            return
        }
        try sessionManager.configureForRecording()
        let url = Self.newRecordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        remaining = maxDuration
        if recorder?.record(forDuration: maxDuration) == true {
            startTimer()
            state = .recording(elapsed: 0)
        } else {
            state = .error("Failed to start recording.")
        }
    }

    func stop() {
        // Stop recording
        recorder?.stop()

        // Immediately reset timer/UI for next recording
        stopTimer()
        remaining = maxDuration
        state = .idle

        // Do NOT set state to .idle here; let the delegate emit .finished
        // Session deactivation happens in the delegate after state update
    }

    func cancel() {
        recorder?.stop()
        if let url = recorder?.url {
            try? FileManager.default.removeItem(at: url)
        }
        recorder = nil
        stopTimer()
        remaining = maxDuration
        state = .idle
        sessionManager.deactivate()
    }

    private func startTimer() {
        stopTimer()
        let start = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let elapsed = Date().timeIntervalSince(start)
            let clamped = min(elapsed, self.maxDuration)
            self.remaining = max(0, self.maxDuration - clamped)
            self.state = .recording(elapsed: clamped)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private static func newRecordingURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = "recording-\(UUID().uuidString).m4a"
        return dir.appendingPathComponent(filename)
    }

    // MARK: AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        stopTimer()
        if flag {
            let url = recorder.url
            let asset = AVURLAsset(url: url)
            let duration = CMTimeGetSeconds(asset.duration)
            state = .finished(fileURL: url, duration: duration.isFinite ? duration : 0)
        } else {
            state = .error("Recording failed.")
        }
        self.recorder = nil
        sessionManager.deactivate()
    }
}
