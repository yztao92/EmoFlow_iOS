import UIKit
import Foundation

// MARK: - 请求结构
struct ChatRequestPayload: Codable {
    let session_id: String
    let user_message: String  // 简化为单个用户消息
    let emotion: String?  // 情绪字段
    let has_image: Bool  // 是否包含图片
    let image_data: String?  // Base64编码的图片数据
}

// MARK: - 响应结构
struct ChatResponseWrapper: Codable {
    let response: ChatAnswer
}

struct ChatAnswer: Codable {
    let answer: String
    let user_heart: Int?  // 移除 references 字段
    let images: [String]?  // 图片ID列表
    let image_urls: [String]?  // 图片URL列表
}

// MARK: - 自定义错误
enum ChatServiceError: Error, LocalizedError, Equatable {
    case networkError(String)
    case invalidResponse
    case timeout
    case unauthorized
    case insufficientHeart

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidResponse:
            return "服务器响应格式错误"
        case .timeout:
            return "请求超时，请检查网络连接"
        case .unauthorized:
            return "用户未授权，请重新登录"
        case .insufficientHeart:
            return "心心数量不足，聊天需要至少2个心心"
        }
    }
}

// MARK: - ChatService 单例
class ChatService {
    static let shared = ChatService()
    private init() {}

    private let url = URL(string: "https://emoflow.net.cn/chat")!
    private let timeoutInterval: TimeInterval = 60.0  // 增加到60秒

    /// 发送聊天请求
    func sendMessage(
        sessionID: String,
        userMessage: String,
        emotion: EmotionType?,
        imageData: Data? = nil
    ) async throws -> String {
        // 首先检查token是否存在
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("❌ 聊天接口 - 未找到用户token，拒绝发送请求")
            throw ChatServiceError.unauthorized
        }
        
        // 检查心心数量是否足够（聊天需要至少2个心心）
        let currentHeartCount = UserDefaults.standard.integer(forKey: "heartCount")
        guard currentHeartCount >= 2 else {
            print("❌ 聊天接口 - 心心数量不足，当前: \(currentHeartCount)，需要: 2")
            throw ChatServiceError.insufficientHeart
        }
        
        let maxRetries = 3
        var lastError: Error?        
        for attempt in 1...maxRetries {
            do {
                return try await performSendMessage(sessionID: sessionID, userMessage: userMessage, emotion: emotion, imageData: imageData)
            } catch let error as ChatServiceError {
                if error == .timeout && attempt < maxRetries {
                    print("⚠️ 第 \(attempt) 次请求超时，准备重试...")
                    lastError = error
                    // 等待一段时间后重试
                    try await Task.sleep(nanoseconds: UInt64(attempt * 2) * 1_000_000_000) // 2秒、4秒、6秒
                    continue
                } else {
                    throw error
                }
            } catch {
                if (error as NSError).code == NSURLErrorTimedOut && attempt < maxRetries {
                    print("⚠️ 第 \(attempt) 次请求超时，准备重试...")
                    lastError = error
                    // 等待一段时间后重试
                    try await Task.sleep(nanoseconds: UInt64(attempt * 2) * 1_000_000_000) // 2秒、4秒、6秒
                    continue
                } else {
                    throw error
                }
            }
        }
        
        // 所有重试都失败了
        throw lastError ?? ChatServiceError.timeout
    }
    
    /// 执行实际的发送消息请求
    private func performSendMessage(
        sessionID: String,
        userMessage: String,
        emotion: EmotionType?,
        imageData: Data?
    ) async throws -> String {
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        
        // 添加认证token - 强制要求token验证
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("❌ 聊天接口 - 未找到用户token，拒绝发送请求")
            throw ChatServiceError.unauthorized
        }
        
        request.addValue(token, forHTTPHeaderField: "token")
        print("🔍 聊天接口 - 添加认证token")

        // 2. 构造请求体
        let hasImage = imageData != nil
        let base64ImageData = imageData?.base64EncodedString()
        
        let payload = ChatRequestPayload(
            session_id: sessionID,
            user_message: userMessage,
            emotion: emotion?.rawValue, // 将 EmotionType 转换为 String
            has_image: hasImage,
            image_data: base64ImageData
        )
        
        print("🔍 聊天接口 - 发送消息: \(userMessage)")
        print("🔍 聊天接口 - 包含图片: \(hasImage)")
        if hasImage {
            print("🔍 聊天接口 - 图片数据大小: \(imageData?.count ?? 0) bytes")
            print("🔍 聊天接口 - Base64数据长度: \(base64ImageData?.count ?? 0) 字符")
            print("🔍 聊天接口 - Base64数据前50字符: \(String(base64ImageData?.prefix(50) ?? ""))")
        } else {
            print("🔍 聊天接口 - 没有图片数据")
        }
        
        request.httpBody = try JSONEncoder().encode(payload)

        // 3. 发起网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // 检查HTTP状态码

            // 4. 检查 HTTP 状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChatServiceError.invalidResponse
            }
            guard httpResponse.statusCode == 200 else {
                // 添加 401 特殊处理
                if httpResponse.statusCode == 401 {
                    // 清除本地 token
                    UserDefaults.standard.removeObject(forKey: "userToken")
                    UserDefaults.standard.removeObject(forKey: "userName")
                    UserDefaults.standard.removeObject(forKey: "userEmail")
                    UserDefaults.standard.removeObject(forKey: "heartCount")
                    UserDefaults.standard.removeObject(forKey: "userBirthday")
                    UserDefaults.standard.removeObject(forKey: "isMember")
                    
                    // 发送登出通知
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .logout, object: nil)
                    }
                    
                    throw ChatServiceError.unauthorized
                } else {
                    throw ChatServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }

            // 5. 解码并返回结果
            let wrapper = try JSONDecoder().decode(ChatResponseWrapper.self, from: data)
            
            // 更新用户的心心值
            if let userHeart = wrapper.response.user_heart {
                UserDefaults.standard.set(userHeart, forKey: "heartCount")
                print("🔍 聊天接口 - 更新心心值")
                
                // 发送心心数量更新通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .heartCountUpdated, object: nil)
                }
            }
            
            
            return wrapper.response.answer

        } catch let error as ChatServiceError {
            print("❌ ChatService - 自定义错误: \(error)")
            throw error
        } catch {
            print("❌ ChatService - 网络错误: \(error)")
            print("❌ ChatService - 错误代码: \((error as NSError).code)")
            print("❌ ChatService - 错误域: \((error as NSError).domain)")
            
            if (error as NSError).code == NSURLErrorTimedOut {
                throw ChatServiceError.timeout
            } else {
                throw ChatServiceError.networkError(error.localizedDescription)
            }
        }
    }
}
