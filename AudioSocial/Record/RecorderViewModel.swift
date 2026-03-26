import Foundation
import Combine
import UIKit

@MainActor
final class RecorderViewModel: ObservableObject {
    @Published var permissionGranted: Bool = false
    @Published var errorMessage: String?
    @Published var elapsed: TimeInterval = 0
    @Published var remaining: TimeInterval = 30
    @Published var isRecording: Bool = false

    private let sessionManager: AudioSessionManager
    private let recorder: AudioRecorder
    private let repository: AudioFeedRepository
    private let playback: AudioPlaybackManager

    init(sessionManager: AudioSessionManager, recorder: AudioRecorder, repository: AudioFeedRepository, playback: AudioPlaybackManager) {
        self.sessionManager = sessionManager
        self.recorder = recorder
        self.repository = repository
        self.playback = playback

        // Initialize permission state
        permissionGranted = sessionManager.micStatus == .granted

        // Observe recorder state changes
        recorder.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle:
                    self.isRecording = false
                    self.elapsed = 0
                    self.remaining = 30
                case .recording(let elapsed):
                    // Ensure playback is stopped while recording
                    
                    self.isRecording = true
                    self.elapsed = elapsed
                    self.remaining = self.recorder.remaining
//                    if case .playing = self.playback.state {
//                        self.playback.stop()
//                    }
                case .finished(let url, _):
                    self.isRecording = false
                    // Save then auto-play newest if nothing is currently playing
                    Task {
                        await self.repository.addRecordedFile(url: url)
                        // If nothing playing, auto-play newest post (index 0)
//                        if case .playing = self.playback.state {
//                            // Already playing; do nothing
//                        } else if let newest = self.repository.posts.first {
//                          //  self.playback.play(post: newest)
//                        }
                    }
                case .error(let message):
                    self.isRecording = false
                    self.errorMessage = message
                }
            }
            .store(in: &cancellables)
    }

    func requestPermission() async {
        let granted = await sessionManager.requestMicrophonePermission()
        permissionGranted = granted
        errorMessage = granted ? nil : "Microphone permission denied."
    }

    func refreshPermissionStatus() {
        sessionManager.refreshPermissionStatus()
        permissionGranted = sessionManager.micStatus == .granted
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func start() {
        // Ensure we have permission
        refreshPermissionStatus()
        guard permissionGranted else {
            errorMessage = "Microphone permission required to record."
            return
        }
        // Stop any playback before recording, to guarantee silence
        if case .playing = playback.state {
            playback.stop()
        }
        do {
            try recorder.start()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        recorder.stop() // AudioRecorder will emit .finished; we will save+auto-play there
        self.playback.stop()
    }

    func cancel() {
        recorder.cancel()
        // Do not auto-play on cancel
    }

    private var cancellables: Set<AnyCancellable> = []
}
