import Foundation
import Combine
import AVFoundation

enum MicrophoneAuthorizationStatus {
    case notDetermined
    case denied
    case granted
}

final class AudioSessionManager: ObservableObject {
    @Published private(set) var micStatus: MicrophoneAuthorizationStatus = .notDetermined

    init() {
        refreshPermissionStatus()
        observeInterruptions()
        observeRouteChanges()
    }

    func refreshPermissionStatus() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined:
                micStatus = .notDetermined
            case .denied:
                micStatus = .denied
            case .granted:
                micStatus = .granted
            @unknown default:
                micStatus = .notDetermined
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined:
                micStatus = .notDetermined
            case .denied:
                micStatus = .denied
            case .granted:
                micStatus = .granted
            @unknown default:
                micStatus = .notDetermined
            }
        }
    }

    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        self.micStatus = granted ? .granted : .denied
                        continuation.resume(returning: granted)
                    }
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        self.micStatus = granted ? .granted : .denied
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    func configureForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: [])
    }

    func configureForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true, options: [])
    }

    func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // Ignore for now; could log
        }
    }

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { _ in
            // Components interested (like playback manager) can also observe this.
        }
    }

    private func observeRouteChanges() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { _ in
            // Could pause playback on route lost (e.g., headphones unplugged).
        }
    }
}
