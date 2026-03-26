import SwiftUI

struct FeedView: View {
    @StateObject var viewModel: FeedViewModel

    init(viewModel: FeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State private var currentPostID: UUID?
    @State private var previousPostID: UUID?

    var body: some View {
        ZStack {
            if viewModel.posts.isEmpty {
                Text("No posts yet.\nRecord your first voice note!")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                GeometryReader { proxy in
                    let height = proxy.size.height

                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.posts) { post in
                                ReelView(
                                    post: post,
                                    isPlaying: isPostPlaying(post),
                                    onPlayPause: {
                                        viewModel.togglePlay(for: post)
                                    }
                                )
                                .frame(width: proxy.size.width, height: height)
                                .id(post.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentPostID)
                    .onChange(of: currentPostID) { _, newID in
                        // Pause previous when moving away
                        if let prevID = previousPostID, prevID != newID {
                            viewModel.pauseIfPlaying()
                        }

                        if let id = newID,
                           let post = viewModel.posts.first(where: { $0.id == id }) {
                        //    viewModel.play(post: post)
                           
                            if let _ = previousPostID {
                                viewModel.play(post: post)
                            }
                            previousPostID = id
                        } else {
                            viewModel.pauseIfPlaying()
                            previousPostID = nil
                        }
                    }
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            // Initialize to first post when appearing
            if currentPostID == nil { currentPostID = viewModel.posts.first?.id }

            // Autoplay when entering Feed if nothing is playing
            if case .playing = viewModel.playback.state {
                // already playing; keep it
            } else if let first = viewModel.posts.first {
                viewModel.play(post: first)
                currentPostID = first.id
                previousPostID = first.id
            }
        }
        .onChange(of: viewModel.posts) { _, newPosts in
            // Keep position valid or jump to first
            if let current = currentPostID, !newPosts.contains(where: { $0.id == current }) {
                currentPostID = newPosts.first?.id
            } else if currentPostID == nil {
                currentPostID = newPosts.first?.id
            }
        }
    }

    private func isPostPlaying(_ post: AudioPost) -> Bool {
        switch viewModel.playback.state {
        case let .playing(id, _, _): return id == post.id
        default: return false
        }
    }
}

struct ReelView: View {
    let post: AudioPost
    let isPlaying: Bool
    let onPlayPause: () -> Void

    var body: some View {
        ZStack {
            // Background styling; you can add artwork or waveform later
            LinearGradient(colors: [Color.black, Color.gray.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text(post.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                    .padding(.horizontal)

                Text(durationString(post.duration))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))

                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 6)
                }
                .padding(.top, 8)

                Spacer()

                HStack {
                    // Left-aligned placeholder for user/channel info, likes, etc.
                    VStack(alignment: .leading, spacing: 6) {
                        Text("@" + post.id.uuidString.prefix(6))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    // Right-aligned action buttons (like, share) placeholders
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.white)
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                    }
                    .font(.title3)
                }
                .padding()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPlayPause()
        }
    }

    private func durationString(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%02d:%02d", s/60, s%60)
    }
}
