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
    let journal: String
    let title: String
    let status: String
    let journal_id: Int? // 新增：日记ID
}

// MARK: - 自定义错误
enum JournalServiceError: Error, LocalizedError {
    case networkError(String)
    case invalidResponse
    case timeout
    case unauthorized
    
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
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        
        // 添加认证token
        if let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty {
            request.addValue(token, forHTTPHeaderField: "token")
            print("🔍 日记接口 - 添加认证token: \(token.prefix(10))...")
        } else {
            print("⚠️ 日记接口 - 未找到用户token")
        }

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
            print("   Parsed Journal: \(wrapper.journal)")
            print("   Parsed Title: \(wrapper.title)")
            print("   Parsed Status: \(wrapper.status)")
            print("   Parsed Journal ID: \(wrapper.journal_id ?? -1)")
            
            // 检查状态
            guard wrapper.status == "success" else {
                print("❌ 日记接口 - 状态错误: \(wrapper.status)")
                throw JournalServiceError.networkError("日记生成失败")
            }
            
            // 检查内容是否为空或失败
            if wrapper.journal.isEmpty || wrapper.journal == "生成失败" {
                print("❌ 日记接口 - 内容生成失败")
                throw JournalServiceError.networkError("日记内容生成失败")
            }
            
            print("✅ 日记接口 - 成功生成日记")
            return (wrapper.journal, wrapper.title, wrapper.journal_id)
            
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
