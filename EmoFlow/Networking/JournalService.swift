//
//  JournalService.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//

import UIKit
import Foundation

// MARK: - 请求结构
struct JournalRequestPayload: Codable {
    let session_id: String
    let messages: [ChatMessageDTO]
}

// MARK: - 响应结构
struct JournalResponse: Codable {
    let journal: String
    let title: String
    let status: String
}

// MARK: - 自定义错误
enum JournalServiceError: Error, LocalizedError {
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

class JournalService {
    static let shared = JournalService()
    private init() {}

    private let url = URL(string: "http://106.14.220.115:8000/journal/generate")!
    private let timeoutInterval: TimeInterval = 30.0

    /// 生成心情日记
    func generateJournal(
        emotions: [EmotionType],
        messages: [ChatMessageDTO]
    ) async throws -> (String, String) {  // 返回 (journal, title)
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        // 2. 准备 session_id（identifierForVendor 是 @MainActor 隔离的，需要 await）
        let vendor = await UIDevice.current.identifierForVendor
        let sessionID = vendor?.uuidString ?? UUID().uuidString

        // 3. 构造请求体（移除 emotions 字段）
        let payload = JournalRequestPayload(
            session_id: sessionID,
            messages: messages
        )
        request.httpBody = try JSONEncoder().encode(payload)

        // 4. 发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 5. 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JournalServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw JournalServiceError.networkError("HTTP \(httpResponse.statusCode)")
            }

            // 6. 解析并返回
            let wrapper = try JSONDecoder().decode(JournalResponse.self, from: data)
            
            // 检查状态
            guard wrapper.status == "success" else {
                throw JournalServiceError.networkError("日记生成失败")
            }
            
            return (wrapper.journal, wrapper.title)
            
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
