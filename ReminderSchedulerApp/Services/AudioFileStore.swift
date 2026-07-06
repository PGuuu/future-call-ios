import Foundation

enum AudioFileStore {
    static func newFileName() -> String {
        "\(UUID().uuidString).m4a"
    }

    static func url(for fileName: String) -> URL {
        documentsDirectory.appendingPathComponent(fileName)
    }

    static func delete(fileName: String) {
        let url = url(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
