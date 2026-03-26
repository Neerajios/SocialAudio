import Foundation
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var posts: [AudioPost] = []
    @Published var currentlyPlayingPostID: UUID?

    let playback: AudioPlaybackManager

    private let repository: AudioFeedRepository

    init(repository: AudioFeedRepository, playback: AudioPlaybackManager) {
        self.repository = repository
        self.playback = playback

        repository.$posts
            .receive(on: DispatchQueue.main)
            .assign(to: &$posts)

        playback.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle:
                    self.currentlyPlayingPostID = nil
                case .playing(let id, _, _), .paused(let id, _, _):
                    self.currentlyPlayingPostID = id
                }
            }
            .store(in: &cancellables)
    }

    func togglePlay(for post: AudioPost) {
        if currentlyPlayingPostID == post.id, case .paused = playback.state {
            playback.resume()
        } else {
            playback.play(post: post)
        }
    }

    func play(post: AudioPost) {
        playback.play(post: post)
    }

    func pauseIfPlaying() {
        if case .playing = playback.state {
            playback.pause()
        }
    }

    func appWillEnterBackground() {
        pauseIfPlaying()
    }

    func appDidBecomeActive() {
        // Optionally resume if desired; safer to leave paused.
    }

    private var cancellables: Set<AnyCancellable> = []
}

