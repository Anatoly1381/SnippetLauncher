
import Foundation

struct SnippetModel: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var tags: [String]
}
