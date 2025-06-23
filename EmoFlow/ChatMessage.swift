import Foundation

enum ChatRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()  // 👈 改为 var
    let role: Role
    let content: String
    var references: [String]? = nil

    enum Role: String, Codable {
        case user
        case assistant
    }

    enum CodingKeys: String, CodingKey {
        case id, role, content, references
    }
}
