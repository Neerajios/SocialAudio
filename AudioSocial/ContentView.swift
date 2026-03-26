//
//  ContentView.swift
//  AudioSocial
//
//  Created by MacBook on 26/03/26.
//

import SwiftUI

enum AppTab: Hashable {
    case record
    case feed
}

struct ContentView: View {
    @EnvironmentObject var sessionManager: AudioSessionManager
    @EnvironmentObject var repository: AudioFeedRepository
    @EnvironmentObject var playback: AudioPlaybackManager

    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordingView(viewModel: RecorderViewModel(
                sessionManager: sessionManager,
                recorder: AudioRecorder(sessionManager: sessionManager),
                repository: repository, playback: playback
            ))
            .tabItem {
                Label("Record", systemImage: "mic.fill")
            }
            .tag(AppTab.record)

            FeedView(viewModel: FeedViewModel(repository: repository, playback: playback))
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
                .tag(AppTab.feed)
        }
        .onChange(of: selectedTab) { _, newTab in
            switch newTab {
            case .record:
                playback.stop()
            case .feed:
                if case .playing = playback.state {
                    // already playing; do nothing
                } else if let first = repository.posts.first {
                    playback.play(post: first)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                if case .playing = playback.state {
                    playback.pause()
                }
            case .inactive, .active:
                break
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    let session = AudioSessionManager()
    let repo = AudioFeedRepository()
    let playback = AudioPlaybackManager(sessionManager: session)
    return ContentView()
        .environmentObject(session)
        .environmentObject(repo)
        .environmentObject(playback)
}
