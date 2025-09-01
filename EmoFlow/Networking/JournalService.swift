//
//  JournalService.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//

import UIKit
import Foundation

// MARK: - 请求结构 (与后端ChatRequest保持一致)
struct JournalRequestPayload: Codable {
    let session_id: String
    let messages: [ChatMessageDTO]
    let emotion: String?  // 添加emotion字段
}

// MARK: - 响应结构
struct JournalResponse: Codable {
    let journal_id: Int?
    let title: String
    let content: String
    let content_html: String
    let content_plain: String
    let content_format: String
    let is_safe: Bool
    let emotion: String
    let status: String
}

// MARK: - 自定义错误
enum JournalServiceError: Error, LocalizedError, Equatable {
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
            return "心心数量不足，生成日记需要至少4个心心"
        }
    }
}

class JournalService {
    static let shared = JournalService()
    private init() {}

    private let url = URL(string: "https://emoflow.net.cn/journal/generate")!
    private let timeoutInterval: TimeInterval = 30.0

    /// 生成心情日记
    func generateJournal(
        emotions: [EmotionType],
        messages: [ChatMessageDTO]
    ) async throws -> (String, String, Int?) {  // 返回 (journal, title, journal_id)
        // 检查心心数量是否足够（生成日记需要至少4个心心）
        let currentHeartCount = UserDefaults.standard.integer(forKey: "heartCount")
        guard currentHeartCount >= 4 else {
            print("❌ 日记接口 - 心心数量不足，当前: \(currentHeartCount)，需要: 4")
            throw JournalServiceError.insufficientHeart
        }
        
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        
        // 添加认证token - 强制要求token验证
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("❌ 日记接口 - 未找到用户token，拒绝发送请求")
            throw JournalServiceError.unauthorized
        }
        
        request.addValue(token, forHTTPHeaderField: "token")
        print("🔍 日记接口 - 添加认证token: \(token.prefix(10))...")

        // 2. 准备 session_id（identifierForVendor 是 @MainActor 隔离的，需要 await）
        let vendor = await UIDevice.current.identifierForVendor
        let sessionID = vendor?.uuidString ?? UUID().uuidString

        // 3. 构造请求体
        let payload = JournalRequestPayload(
            session_id: sessionID,
            messages: messages,
            emotion: emotions.first?.rawValue  // 取第一个emotion
        )
        
        // 调试：打印发送给后端的数据
        print("🔍 日记接口 - 前端发送给后端的数据:")
        print("   URL: \(url)")
        print("   Session ID: \(sessionID)")
        print("   Messages Count: \(messages.count)")
        for (index, message) in messages.enumerated() {
            print("   Message \(index + 1): role=\(message.role), content=\(message.content)")
        }
        
        // 将payload转换为字典以便打印
        let payloadDict: [String: Any] = [
            "session_id": sessionID,
            "messages": messages.map { [
                "role": $0.role,
                "content": $0.content
            ] },
            "emotion": emotions.first?.rawValue ?? ""
        ]
        print("   JSON Payload: \(payloadDict)")
        
        request.httpBody = try JSONEncoder().encode(payload)

        // 4. 发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 5. 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JournalServiceError.invalidResponse
            }
            
            print("🔍 日记接口 - 后端响应:")
            print("   HTTP Status Code: \(httpResponse.statusCode)")
            print("   Response Headers: \(httpResponse.allHeaderFields)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ 日记接口 - HTTP错误: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response Body: \(responseString)")
                }
                
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
                    
                    throw JournalServiceError.unauthorized
                } else {
                    throw JournalServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }

            // 6. 解析并返回
            print("🔍 日记接口 - 解析响应数据:")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Raw Response: \(responseString)")
            }

            let wrapper = try JSONDecoder().decode(JournalResponse.self, from: data)
            print("   Parsed Journal ID: \(wrapper.journal_id ?? -1)")
            print("   Parsed Title: \(wrapper.title)")
            print("   Parsed Content: \(wrapper.content)")
            print("   Parsed Status: \(wrapper.status)")
            print("   Parsed Emotion: \(wrapper.emotion)")
            
            // 检查状态
            guard wrapper.status == "success" else {
                print("❌ 日记接口 - 状态错误: \(wrapper.status)")
                throw JournalServiceError.networkError("日记生成失败")
            }
            
            // 检查内容是否为空或失败
            if wrapper.content.isEmpty || wrapper.content == "生成失败" {
                print("❌ 日记接口 - 内容生成失败")
                throw JournalServiceError.networkError("日记内容生成失败")
            }
            
            // 更新用户的心心值
            // 注意：后端没有返回user_heart字段，所以这里暂时不更新
            // 如果需要更新心心值，需要后端在响应中添加user_heart字段
            
            print("✅ 日记接口 - 成功生成日记")
            return (wrapper.content, wrapper.title, wrapper.journal_id)
            
        } catch let error as JournalServiceError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw JournalServiceError.timeout
            } else {
                throw JournalServiceError.networkError(error.localizedDescription)
            }
        }
    }
}
