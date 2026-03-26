import Foundation
import AVFoundation
import Combine

final class AudioFeedRepository: ObservableObject {
    @Published private(set) var posts: [AudioPost] = []

    init() {
        // Optionally seed with local mock data. For now, start empty.
    }

    func loadMockIfAvailable() {
        // If you add bundled audio files later, you can load them here.
    }

    func addRecordedFile(url: URL) async {
        let duration = await Self.fileDuration(url: url) ?? 0
        let title = "Voice note \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
        let post = AudioPost(title: title, fileURL: url, duration: duration)
        await MainActor.run {
            posts.insert(post, at: 0)
        }
    }

    static func fileDuration(url: URL) async -> TimeInterval? {
        await withCheckedContinuation { continuation in
            let asset = AVURLAsset(url: url)
            let keys = ["duration"]
            asset.loadValuesAsynchronously(forKeys: keys) {
                let status = asset.statusOfValue(forKey: "duration", error: nil)
                if status == .loaded {
                    let seconds = CMTimeGetSeconds(asset.duration)
                    continuation.resume(returning: seconds.isFinite ? seconds : nil)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
