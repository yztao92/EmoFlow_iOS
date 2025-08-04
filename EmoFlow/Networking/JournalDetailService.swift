//
//  JournalDetailService.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/1/27.
//

import Foundation

// MARK: - 响应结构
struct JournalDetailResponse: Codable {
    let status: String
    let journal: JournalData
}

// MARK: - 自定义错误
enum JournalDetailServiceError: Error, LocalizedError {
    case networkError(String)
    case invalidResponse
    case timeout
    case unauthorized
    case notFound
    
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
        case .notFound:
            return "日记不存在"
        }
    }
}

// MARK: - JournalDetailService 单例
class JournalDetailService {
    static let shared = JournalDetailService()
    private init() {}
    
    private let baseURL = "https://emoflow.net.cn/journal/"
    private let timeoutInterval: TimeInterval = 30.0
    
    /// 获取日记详情
    func fetchJournalDetail(journalId: Int) async throws -> ChatRecord {
        guard let url = URL(string: baseURL + "\(journalId)") else {
            throw JournalDetailServiceError.invalidResponse
        }
        
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        
        // 添加认证token
        if let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty {
            request.addValue(token, forHTTPHeaderField: "token")
            print("🔍 日记详情接口 - 添加认证token: \(token.prefix(10))...")
        } else {
            print("⚠️ 日记详情接口 - 未找到用户token")
            throw JournalDetailServiceError.unauthorized
        }
        
        print("🔍 日记详情接口 - 请求URL: \(request.url?.absoluteString ?? "")")
        
        // 2. 发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 3. 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JournalDetailServiceError.invalidResponse
            }
            
            print("🔍 日记详情接口 - 后端响应:")
            print("   HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ 日记详情接口 - HTTP错误: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response Body: \(responseString)")
                }
                
                if httpResponse.statusCode == 401 {
                    throw JournalDetailServiceError.unauthorized
                } else if httpResponse.statusCode == 404 {
                    throw JournalDetailServiceError.notFound
                } else {
                    throw JournalDetailServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // 4. 解析响应数据
            print("🔍 日记详情接口 - 解析响应数据:")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Raw Response: \(responseString)")
            }
            
            let wrapper = try JSONDecoder().decode(JournalDetailResponse.self, from: data)
            print("   Parsed Journal ID: \(wrapper.journal.id)")
            print("   Parsed Title: \(wrapper.journal.title)")
            
            // 5. 转换为ChatRecord格式
            guard let chatRecord = convertJournalDataToChatRecord(wrapper.journal) else {
                throw JournalDetailServiceError.invalidResponse
            }
            
            print("✅ 日记详情接口 - 成功获取日记详情")
            return chatRecord
            
        } catch let error as JournalDetailServiceError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw JournalDetailServiceError.timeout
            } else {
                throw JournalDetailServiceError.networkError(error.localizedDescription)
            }
        }
    }
    
    /// 获取并缓存日记详情
    func fetchAndCacheJournalDetail(journalId: Int) async throws -> ChatRecord {
        let chatRecord = try await fetchJournalDetail(journalId: journalId)
        
        // 缓存到本地
        let cacheKey = "journal_detail_\(journalId)"
        if let data = try? JSONEncoder().encode(chatRecord) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            print("✅ 日记详情已缓存: \(cacheKey)")
        }
        
        return chatRecord
    }
    
    /// 从本地缓存获取日记详情
    func getCachedJournalDetail(journalId: Int) -> ChatRecord? {
        let cacheKey = "journal_detail_\(journalId)"
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let chatRecord = try? JSONDecoder().decode(ChatRecord.self, from: data) else {
            return nil
        }
        return chatRecord
    }
    
    /// 检查日记详情是否已缓存
    func isDetailCached(journalId: Int) -> Bool {
        let cacheKey = "journal_detail_\(journalId)"
        return UserDefaults.standard.data(forKey: cacheKey) != nil
    }
    
    /// 清除日记详情缓存
    func clearDetailCache(journalId: Int) {
        let cacheKey = "journal_detail_\(journalId)"
        UserDefaults.standard.removeObject(forKey: cacheKey)
        print("🗑️ 已清除日记详情缓存: \(cacheKey)")
    }
    
    /// 将后端JournalData转换为前端ChatRecord
    private func convertJournalDataToChatRecord(_ journalData: JournalData) -> ChatRecord? {
        // 转换消息格式
        let messages = journalData.messages.map { dto in
            ChatMessage(role: dto.role == "user" ? .user : .assistant, content: dto.content)
        }
        
        // 转换时间格式，使用创建时间
        let dateFormatter = ISO8601DateFormatter()
        let date = journalData.created_at.flatMap { dateFormatter.date(from: $0) } ?? Date()
        
        // 转换情绪类型（从标题或内容中推断）
        let emotion = inferEmotionFromContent(journalData.content)
        
        return ChatRecord(
            id: UUID(), // 前端使用UUID，后端使用Int
            backendId: journalData.id, // 保存后端ID
            date: date, // 使用创建时间
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