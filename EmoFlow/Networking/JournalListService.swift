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
    let emotion: String?  // 添加emotion字段
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
            print("🔍 日记列表接口 - 开始转换日记数据:")
            print("   总日记数: \(wrapper.journals.count)")
            print("   分页信息: limit=\(wrapper.limit), offset=\(wrapper.offset), total=\(wrapper.total)")
            
            for (index, journalData) in wrapper.journals.enumerated() {
                print("   📝 日记 \(index + 1):")
                print("      ID: \(journalData.id)")
                print("      标题: \(journalData.title)")
                print("      内容: \(journalData.content.prefix(100))\(journalData.content.count > 100 ? "..." : "")")
                print("      创建时间: \(journalData.created_at ?? "null")")
                print("      更新时间: \(journalData.updated_at ?? "null")")
                print("      消息数量: \(journalData.messages.count)")
                print("      会话ID: \(journalData.session_id)")
                
                // 打印消息内容
                for (msgIndex, message) in journalData.messages.enumerated() {
                    print("       消息 \(msgIndex + 1): role=\(message.role), content=\(message.content.prefix(50))\(message.content.count > 50 ? "..." : "")")
                }
                print("")
            }
            
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
        print("🔄 转换日记 ID \(journalData.id):")
        
        // 转换消息格式
        let messages = journalData.messages.map { dto in
            ChatMessage(role: dto.role == "user" ? .user : .assistant, content: dto.content)
        }
        print("   消息数量: \(messages.count)")
        
        // 使用创建时间作为主要时间
        let createdDate = parseBackendTime(journalData.created_at)
        
        print("   创建时间: \(journalData.created_at ?? "null") -> 解析后: \(createdDate)")
        
        // 转换情绪类型（从后端emotion字段获取）
        let emotion = convertBackendEmotionToEmotionType(journalData.emotion)
        print("   后端情绪: \(journalData.emotion ?? "null") -> 转换后: \(emotion.rawValue)")
        
        let chatRecord = ChatRecord(
            id: UUID(), // 前端使用UUID，后端使用Int
            backendId: journalData.id, // 保存后端ID
            date: createdDate, // 使用创建时间
            messages: messages,
            summary: journalData.content,
            emotion: emotion,
            title: journalData.title
        )
        
        print("   ✅ 转换完成: 标题=\(chatRecord.title ?? "无标题"), 情绪=\(emotion.rawValue)")
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
        print("⚠️ 无法解析时间格式: \(timeString)，使用当前时间")
        return Date()
    }
    
    /// 将后端emotion字段转换为EmotionType
    private func convertBackendEmotionToEmotionType(_ backendEmotion: String?) -> EmotionType {
        guard let emotion = backendEmotion else {
            print("   -> 后端emotion为空，默认使用peaceful")
            return .peaceful
        }
        
        switch emotion.lowercased() {
        case "angry":
            print("   -> 后端emotion: angry")
            return .angry
        case "sad":
            print("   -> 后端emotion: sad")
            return .sad
        case "unhappy":
            print("   -> 后端emotion: unhappy")
            return .unhappy
        case "happy":
            print("   -> 后端emotion: happy")
            return .happy
        case "happiness":
            print("   -> 后端emotion: happiness")
            return .happiness
        case "peaceful":
            print("   -> 后端emotion: peaceful")
            return .peaceful
        default:
            print("   -> 后端emotion: \(emotion) (未知类型，默认使用peaceful)")
            return .peaceful
        }
    }
} 