import UIKit
import Foundation

// MARK: - 请求结构
struct ChatRequestPayload: Codable {
    let session_id: String
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

// MARK: - 自定义错误
enum ChatServiceError: Error, LocalizedError {
    case networkError(String)
    case invalidResponse
    case timeout

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidResponse:
            return "服务器响应格式错误"
        case .timeout:
            return "请求超时，请检查网络连接"
        }
    }
}

// MARK: - ChatService 单例
class ChatService {
    static let shared = ChatService()
    private init() {}

    private let url = URL(string: "http://106.14.220.115:8000/chat")!
    private let timeoutInterval: TimeInterval = 30.0

    /// 发送聊天请求
    func sendMessage(
        sessionID: String,
        emotions: [EmotionType],
        messages: [ChatMessageDTO]
    ) async throws -> (String, [String]) {
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        // 2. 构造请求体
        let payload = ChatRequestPayload(
            session_id: sessionID,
            messages: messages
        )
        request.httpBody = try JSONEncoder().encode(payload)

        // 3. 发起网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // 4. 检查 HTTP 状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChatServiceError.invalidResponse
            }
            guard httpResponse.statusCode == 200 else {
                throw ChatServiceError.networkError("HTTP \(httpResponse.statusCode)")
            }

            // 5. 解码并返回结果
            let wrapper = try JSONDecoder().decode(ChatResponseWrapper.self, from: data)
            return (wrapper.response.answer, wrapper.response.references)

        } catch let error as ChatServiceError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw ChatServiceError.timeout
            } else {
                throw ChatServiceError.networkError(error.localizedDescription)
            }
        }
    }
}
