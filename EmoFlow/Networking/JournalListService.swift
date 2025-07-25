//
//  JournalListService.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/1/27.
//

import Foundation

// MARK: - 响应结构
struct JournalListResponse: Codable {
    let status: String
    let journals: [JournalData]
    let total: Int
    let limit: Int
    let offset: Int
}

struct JournalData: Codable {
    let id: Int
    let title: String
    let content: String
    let messages: [ChatMessageDTO]
    let session_id: String
    let created_at: String?
    let updated_at: String?
}

// MARK: - 自定义错误
enum JournalListServiceError: Error, LocalizedError {
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

// MARK: - JournalListService 单例
class JournalListService {
    static let shared = JournalListService()
    private init() {}
    
    private let url = URL(string: "https://emoflow.net.cn/journal/list")!
    private let timeoutInterval: TimeInterval = 30.0
    
    /// 获取用户日记列表
    func fetchJournals(limit: Int = 20, offset: Int = 0) async throws -> [ChatRecord] {
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        
        // 添加认证token
        if let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty {
            request.addValue(token, forHTTPHeaderField: "token")
            print("🔍 日记列表接口 - 添加认证token: \(token.prefix(10))...")
        } else {
            print("⚠️ 日记列表接口 - 未找到用户token")
            throw JournalListServiceError.unauthorized
        }
        
        // 添加查询参数
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        request.url = components.url
        
        print("🔍 日记列表接口 - 请求URL: \(request.url?.absoluteString ?? "")")
        
        // 2. 发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 3. 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JournalListServiceError.invalidResponse
            }
            
            print("🔍 日记列表接口 - 后端响应:")
            print("   HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ 日记列表接口 - HTTP错误: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response Body: \(responseString)")
                }
                
                if httpResponse.statusCode == 401 {
                    throw JournalListServiceError.unauthorized
                } else {
                    throw JournalListServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // 4. 解析响应数据
            print("🔍 日记列表接口 - 解析响应数据:")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Raw Response: \(responseString)")
            }
            
            let wrapper = try JSONDecoder().decode(JournalListResponse.self, from: data)
            print("   Parsed Journals Count: \(wrapper.journals.count)")
            print("   Total: \(wrapper.total)")
            
            // 5. 转换为ChatRecord格式
            let chatRecords = wrapper.journals.compactMap { journalData -> ChatRecord? in
                return convertJournalDataToChatRecord(journalData)
            }
            
            print("✅ 日记列表接口 - 成功获取 \(chatRecords.count) 条日记")
            return chatRecords
            
        } catch let error as JournalListServiceError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw JournalListServiceError.timeout
            } else {
                throw JournalListServiceError.networkError(error.localizedDescription)
            }
        }
    }
    
    /// 同步日记列表到本地缓存
    func syncJournals() async {
        do {
            let journals = try await fetchJournals(limit: 100, offset: 0) // 获取更多数据
            RecordManager.saveAll(journals)
            print("✅ 日记列表同步成功，共 \(journals.count) 条")
        } catch {
            print("❌ 日记列表同步失败: \(error)")
        }
    }
    
    /// 将后端JournalData转换为前端ChatRecord
    private func convertJournalDataToChatRecord(_ journalData: JournalData) -> ChatRecord? {
        // 转换消息格式
        let messages = journalData.messages.map { dto in
            ChatMessage(role: dto.role == "user" ? .user : .assistant, content: dto.content)
        }
        
        // 转换时间格式
        let dateFormatter = ISO8601DateFormatter()
        let date = journalData.created_at.flatMap { dateFormatter.date(from: $0) } ?? Date()
        
        // 转换情绪类型（从标题或内容中推断）
        let emotion = inferEmotionFromContent(journalData.content)
        
        return ChatRecord(
            id: UUID(), // 前端使用UUID，后端使用Int
            backendId: journalData.id, // 保存后端ID
            date: date,
            messages: messages,
            summary: journalData.content,
            emotion: emotion,
            title: journalData.title
        )
    }
    
    /// 从内容中推断情绪类型
    private func inferEmotionFromContent(_ content: String) -> EmotionType {
        let lowerContent = content.lowercased()
        
        if lowerContent.contains("生气") || lowerContent.contains("愤怒") || lowerContent.contains("恼火") {
            return .angry
        } else if lowerContent.contains("悲伤") || lowerContent.contains("难过") || lowerContent.contains("伤心") {
            return .sad
        } else if lowerContent.contains("不开心") || lowerContent.contains("沮丧") || lowerContent.contains("郁闷") {
            return .unhappy
        } else if lowerContent.contains("开心") || lowerContent.contains("高兴") || lowerContent.contains("快乐") {
            return .happy
        } else if lowerContent.contains("平和") || lowerContent.contains("平静") || lowerContent.contains("安宁") {
            return .peaceful
        } else if lowerContent.contains("幸福") || lowerContent.contains("满足") || lowerContent.contains("喜悦") {
            return .happiness
        }
        
        return .happy // 默认情绪
    }
} 