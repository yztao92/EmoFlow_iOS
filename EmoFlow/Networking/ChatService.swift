import UIKit
import Foundation
// MARK: - 请求结构
struct ChatRequestPayload: Codable {
    let session_id: String
    let emotions: [String]
    let messages: [ChatMessageDTO]
}

// MARK: - 消息结构
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

// MARK: - ChatService 单例
class ChatService {
    static let shared = ChatService()
    private init() {}

    private let url = URL(string: "http://47.238.87.240:8000/chat")!

    /// 发送聊天请求
    func sendMessage(
        emotions: [EmotionType],
        messages: [ChatMessageDTO]
    ) async throws -> (String, [String]) {
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // 2. 准备 session_id（identifierForVendor 是 @MainActor 隔离的，需要 await）
        let vendor = await UIDevice.current.identifierForVendor
        let sessionID = vendor?.uuidString ?? UUID().uuidString

        // 3. 构造请求体
        let payload = ChatRequestPayload(
            session_id: sessionID,
            emotions: emotions.map { $0.rawValue },
            messages: messages
        )
        request.httpBody = try JSONEncoder().encode(payload)

        // 4. 发起网络请求
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. 调试：打印原始响应
        if let text = String(data: data, encoding: .utf8) {
            print("📦 原始返回内容： \(text)")
        }

        // 6. 解析并返回
        let wrapper = try JSONDecoder().decode(ChatResponseWrapper.self, from: data)
        return (wrapper.response.answer, wrapper.response.references)
    }
}
