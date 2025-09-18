import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var role: Role
    var content: String
    var references: [String]? = nil  // RAG 相关引用内容（可选）
    var imageData: Data? = nil  // 图片数据（可选）

    enum Role: String, Codable {
        case user
        case assistant
    }

    enum CodingKeys: String, CodingKey {
        case id, role, content, references, imageData
    }
}
