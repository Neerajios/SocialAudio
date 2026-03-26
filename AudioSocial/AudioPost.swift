import Foundation

struct AudioPost: Identifiable, Equatable {
    let id: UUID
    var title: String
    var fileURL: URL
    var duration: TimeInterval

    init(id: UUID = UUID(), title: String, fileURL: URL, duration: TimeInterval) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
    }
}
