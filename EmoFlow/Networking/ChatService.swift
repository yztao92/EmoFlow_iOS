import Foundation

// MARK: - 请求结构
struct ChatRequestPayload: Codable {
    let emotions: [String]
    let messages: [ChatMessageDTO]
}

// MARK: - 消息结构（避免与项目已有类型冲突）
struct ChatMessageDTO: Codable {
    let role: String  // "user" or "assistant"
    let content: String
}

// MARK: - 响应结构
struct ChatResponseWrapper: Codable {
    let response: ChatAnswer
}

struct ChatAnswer: Codable {
    let answer: String
    let references: [String]
}

// MARK: - ChatService 单例类
class ChatService {
    static let shared = ChatService()
    private init() {}

    private let url = URL(string: "http://47.238.87.240:8000/chat")!

    /// 向后端发送消息
    /// - Returns: (AI回答内容, 引用内容列表)
    func sendMessage(emotions: [EmotionType], messages: [ChatMessageDTO]) async throws -> (String, [String]) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let emotionStrings = emotions.map { $0.rawValue }
        let payload = ChatRequestPayload(emotions: emotionStrings, messages: messages)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await URLSession.shared.data(for: request)

        print("📦 原始返回内容：", String(data: data, encoding: .utf8) ?? "无数据")

        do {
            let decoded = try JSONDecoder().decode(ChatResponseWrapper.self, from: data)
            return (decoded.response.answer, decoded.response.references)
        } catch {
            print("❌ 解码失败: \(error)")
            throw error
        }
    }
}
