import SwiftUI

struct AudioPostRowView: View {
    let post: AudioPost
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.headline)
                Text(durationString(post.duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onTap) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 8)
    }

    private func durationString(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%02d:%02d", s/60, s%60)
    }
}
