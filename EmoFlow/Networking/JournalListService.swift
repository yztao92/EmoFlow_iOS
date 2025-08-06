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
    let content: String  // 向后兼容
    let contentHtml: String  // 新增：净化后的HTML内容
    let contentPlain: String  // 新增：纯文本内容
    let contentFormat: String  // 新增：内容格式
    let isSafe: Bool  // 新增：安全标识
    let messages: [ChatMessageDTO]
    let session_id: String
    let created_at: String?
    let updated_at: String?
    let emotion: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, messages, session_id, created_at, updated_at, emotion
        case contentHtml = "content_html"
        case contentPlain = "content_plain"
        case contentFormat = "content_format"
        case isSafe = "is_safe"
    }
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
        } else {
            throw JournalListServiceError.unauthorized
        }
        
        // 添加查询参数
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        request.url = components.url
        
        // 2. 发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 3. 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JournalListServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    throw JournalListServiceError.unauthorized
                } else {
                    throw JournalListServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // 4. 解析响应数据
            do {
                let wrapper = try JSONDecoder().decode(JournalListResponse.self, from: data)
                
                // 5. 转换为ChatRecord格式
                let chatRecords = wrapper.journals.compactMap { journalData -> ChatRecord? in
                    return convertJournalDataToChatRecord(journalData)
                }
                
                return chatRecords
                
            } catch {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   原始响应: \(responseString)")
                }
                throw JournalListServiceError.invalidResponse
            }
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
        } catch {
            // 日记列表同步失败
        }
    }
    
    /// 将后端JournalData转换为前端ChatRecord
    private func convertJournalDataToChatRecord(_ journalData: JournalData) -> ChatRecord? {
        // 转换消息格式
        let messages = journalData.messages.map { dto in
            ChatMessage(role: dto.role == "user" ? .user : .assistant, content: dto.content)
        }
        
        // 使用创建时间作为主要时间
        let createdDate = parseBackendTime(journalData.created_at)
        
        // 转换情绪类型（从后端emotion字段获取）
        let emotion = convertBackendEmotionToEmotionType(journalData.emotion)
        
        let chatRecord = ChatRecord(
            id: UUID(), // 前端使用UUID，后端使用Int
            backendId: journalData.id, // 保存后端ID
            date: createdDate, // 使用创建时间
            messages: messages,
            summary: journalData.contentHtml, // 使用净化后的HTML内容
            emotion: emotion,
            title: journalData.title
        )
        
        return chatRecord
    }
    
    /// 解析后端时间，直接使用，不做时区转换
    private func parseBackendTime(_ timeString: String?) -> Date {
        guard let timeString = timeString else { return Date() }
        
        // 尝试多种时间格式，直接解析为本地时间
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss.SSSSSS",
            "yyyy-MM-dd HH:mm:ss.SSS",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = TimeZone.current // 直接使用本地时区
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = formatter.date(from: timeString) {
                return date
            }
        }
        
        // 如果所有格式都失败，返回当前时间
        return Date()
    }
    
    /// 将后端emotion字段转换为EmotionType
    private func convertBackendEmotionToEmotionType(_ backendEmotion: String?) -> EmotionType {
        guard let emotion = backendEmotion else {
            return .peaceful
        }
        
        switch emotion.lowercased() {
        case "angry":
            return .angry
        case "sad":
            return .sad
        case "unhappy":
            return .unhappy
        case "happy":
            return .happy
        case "happiness":
            return .happiness
        case "peaceful":
            return .peaceful
        default:
            return .peaceful
        }
    }
} 