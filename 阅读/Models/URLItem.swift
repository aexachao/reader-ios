import Foundation

struct URLItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var urlString: String

    init(id: UUID = UUID(), name: String, urlString: String) {
        self.id = id
        self.name = name
        self.urlString = URLItem.normalized(urlString)
    }

    static func normalized(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return s }

        // 如果没有 scheme，则默认 https
        if URL(string: s)?.scheme == nil {
            s = "https://" + s
        }

        // 移除尾部多余的斜杠（除非是根）
        if s.count > 1, s.hasSuffix("/") {
            s.removeLast()
        }

        return s
    }
}
