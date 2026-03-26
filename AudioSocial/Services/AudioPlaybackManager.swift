import Foundation
import AVFoundation
import Combine

enum PlaybackState: Equatable {
    case idle
    case playing(postID: UUID, currentTime: TimeInterval, duration: TimeInterval)
    case paused(postID: UUID, currentTime: TimeInterval, duration: TimeInterval)
}

final class AudioPlaybackManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var state: PlaybackState = .idle

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private let sessionManager: AudioSessionManager

    init(sessionManager: AudioSessionManager) {
        self.sessionManager = sessionManager
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }

    func play(post: AudioPost) {
        if case let .playing(currentID, _, _) = state, currentID == post.id {
            pause()
            return
        }
        do { try sessionManager.configureForPlayback() } catch {}
        stopInternal(notify: false)

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: post.fileURL)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            player = newPlayer
            player?.play()
            startTimer(for: post)
        } catch {
            stopInternal(notify: true)
        }
    }

    func pause() {
        guard let player, case let .playing(id, _, _) = state else { return }
        player.pause()
        state = .paused(postID: id, currentTime: player.currentTime, duration: player.duration)
        stopTimer()
    }

    func resume() {
        guard let player, case let .paused(id, _, _) = state else { return }
        player.play()
        state = .playing(postID: id, currentTime: player.currentTime, duration: player.duration)
        startTimer(forPostID: id)
    }

    func stop() {
        stopInternal(notify: true)
    }

    private func stopInternal(notify: Bool) {
        stopTimer()
        player?.stop()
        player = nil
        if notify {
            state = .idle
            sessionManager.deactivate()
        }
    }

    private func startTimer(for post: AudioPost) {
        startTimer(forPostID: post.id)
    }

    private func startTimer(forPostID id: UUID) {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            if player.isPlaying {
                self.state = .playing(postID: id, currentTime: player.currentTime, duration: player.duration)
            } else {
                self.state = .paused(postID: id, currentTime: player.currentTime, duration: player.duration)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopInternal(notify: true)
    }

    // MARK: Interruptions/Route
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            if case .playing = state { pause() }
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resume()
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        if reason == .oldDeviceUnavailable {
            if case .playing = state { pause() }
        }
    }
}
