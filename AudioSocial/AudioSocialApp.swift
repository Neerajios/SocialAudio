//
//  AudioSocialApp.swift
//  AudioSocial
//
//  Created by MacBook on 26/03/26.
//

import SwiftUI

@main
struct AudioSocialApp: App {
    @StateObject private var sessionManager = AudioSessionManager()
    @StateObject private var repository = AudioFeedRepository()
    @StateObject private var playback: AudioPlaybackManager

    init() {
        let session = AudioSessionManager()
        _sessionManager = StateObject(wrappedValue: session)
        _repository = StateObject(wrappedValue: AudioFeedRepository())
        _playback = StateObject(wrappedValue: AudioPlaybackManager(sessionManager: session))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .environmentObject(repository)
                .environmentObject(playback)
        }
    }
}
