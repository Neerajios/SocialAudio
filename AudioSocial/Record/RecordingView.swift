import SwiftUI

struct RecordingView: View {
    @StateObject var viewModel: RecorderViewModel

    init(viewModel: RecorderViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Record up to 30 seconds")
                .font(.headline)

            permissionSection

            Text(timeString(viewModel.elapsed))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .padding(.top, 16)

            HStack(spacing: 24) {
                Button {
                    viewModel.isRecording ? viewModel.stop() : viewModel.start()
                } label: {
                    Text(viewModel.isRecording ? "Stop" : "Record")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.permissionGranted)

                if viewModel.isRecording {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.refreshPermissionStatus()
        }
    }

    @ViewBuilder
    private var permissionSection: some View {
        if !viewModel.permissionGranted {
            VStack(spacing: 8) {
                Text("Microphone access is required to record voice notes.")
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button("Request Permission") {
                        Task { await viewModel.requestPermission() }
                    }
                    Button("Open Settings") {
                        viewModel.openSettings()
                    }
                }
            }
            .padding()
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(12)
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%02d:%02d", s/60, s%60)
    }
}
