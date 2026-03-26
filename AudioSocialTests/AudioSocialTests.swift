//
//  AudioSocialTests.swift
//  AudioSocialTests
//
//  Created by MacBook on 26/03/26.
//

import XCTest
@testable import AudioSocial
import Combine

@MainActor
final class AudioSocialTests: XCTestCase {

    var sessionManager: AudioSessionManager!
        var repository: AudioFeedRepository!
        var playback: AudioPlaybackManager!
        var recorder: AudioRecorder!
        var viewModel: RecorderViewModel!

        var cancellables: Set<AnyCancellable>!

        override func setUp() {
            super.setUp()
            sessionManager = AudioSessionManager()
            repository = AudioFeedRepository()
            playback = AudioPlaybackManager(sessionManager: sessionManager)
            recorder = AudioRecorder(sessionManager: sessionManager)
            viewModel = RecorderViewModel(
                sessionManager: sessionManager,
                recorder: recorder,
                repository: repository,
                playback: playback
            )
            cancellables = []
        }

        override func tearDown() {
            cancellables = nil
            viewModel = nil
            recorder = nil
            playback = nil
            repository = nil
            sessionManager = nil
            super.tearDown()
        }

        // MARK: - Permission Tests

        func testPermissionInitialState() {
            // We cannot force micStatus, just verify mapping
            viewModel.refreshPermissionStatus()

            XCTAssertNotNil(viewModel.permissionGranted)
        }

        // MARK: - Recording Tests

        func testStartRecordingWithPermissionFlag() {
            // Simulate permission granted (ViewModel level only)
            viewModel.permissionGranted = true

            viewModel.start()

            // We can't assert AVAudioRecorder, but at least no error
            XCTAssertNil(viewModel.errorMessage)
        }

        func testStopRecordingResetsState() {
            viewModel.permissionGranted = true

            viewModel.start()
            viewModel.stop()

            XCTAssertFalse(viewModel.isRecording)
        }

        func testCancelRecordingResetsState() {
            viewModel.permissionGranted = true

            viewModel.start()
            viewModel.cancel()

            XCTAssertFalse(viewModel.isRecording)
            XCTAssertEqual(viewModel.elapsed, 0)
        }

        // MARK: - Repository Tests

        func testAddRecordedFileAddsPost() async {
            let dummyURL = URL(fileURLWithPath: "/tmp/test.m4a")

            await repository.addRecordedFile(url: dummyURL)

            XCTAssertEqual(repository.posts.count, 1)
        }

        func testNewPostInsertedAtTop() async {
            let url1 = URL(fileURLWithPath: "/tmp/1.m4a")
            let url2 = URL(fileURLWithPath: "/tmp/2.m4a")

            await repository.addRecordedFile(url: url1)
            await repository.addRecordedFile(url: url2)

            XCTAssertEqual(repository.posts.first?.fileURL, url2)
        }

        // MARK: - Playback Tests

        func testInitialPlaybackStateIsIdle() {
            XCTAssertEqual(playback.state, .idle)
        }

        func testPauseWithoutPlayingDoesNothing() {
            playback.pause()

            XCTAssertEqual(playback.state, .idle)
        }

        // MARK: - FeedViewModel Tests

        func testFeedViewModelReceivesPosts() async {
            let feedVM = FeedViewModel(repository: repository, playback: playback)

            let url = URL(fileURLWithPath: "/tmp/test.m4a")
            await repository.addRecordedFile(url: url)

            // Wait for Combine propagation
            let expectation = XCTestExpectation(description: "Posts updated")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                XCTAssertEqual(feedVM.posts.count, 1)
                expectation.fulfill()
            }

            await fulfillment(of: [expectation], timeout: 1)
        }

       
    }
