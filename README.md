# Social Audio App

Simple iOS app to record and play short audio clips.

---

## Architecture

Used **MVVM** with some helper managers.

- Views → SwiftUI screens (Recording, Feed)
- ViewModels → handle state and logic
- Managers:
  - AudioSessionManager → permissions + session
  - AudioRecorder → recording
  - AudioPlaybackManager → playback
- Repository → stores recorded audio list

Kept things simple and separated UI from logic.

---

## Audio Handling

**Single playback**
- Only one audio plays at a time
- Starting new audio stops previous one

**Lifecycle**
- App background → pause playback
- Switching to record screen → stop playback
- Calls / headphone removal → pause

---

## Tradeoffs

- Used AVFoundation directly → quick but harder to test
- Local storage only → no backend
- Basic error handling → focused on main flow

---

## Improvements (if more time)

- Add backend (upload + fetch audio)
- Better UI (progress bar, waveform)
- Improve error handling
- Add more tests with mocks

---

## Scaling

- Move feed to API
- Upload audio to server 
- Add caching + offline support
- Split into modules if app grows

---

## Run

⌘ + R

## Tests

⌘ + U

---

## Tech

Swift, SwiftUI, Combine, AVFoundation
