//
//  JournalDetailService.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/1/27.
//

import Foundation

// MARK: - 缓存数据结构
struct CacheData: Codable {
    let record: ChatRecord
    let timestamp: Date
}

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
        } else {
            print("⚠️ 日记详情接口 - 未找到用户token")
            throw JournalDetailServiceError.unauthorized
        }
        
        print("🔍 日记详情接口 - 请求日记ID: \(journalId)")
        
        // 2. 发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 3. 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JournalDetailServiceError.invalidResponse
            }
            
            print("📡 日记详情接口 - HTTP状态码: \(httpResponse.statusCode)")
            
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
                
                throw JournalDetailServiceError.unauthorized
            } else {
                guard httpResponse.statusCode == 200 else {
                    throw JournalDetailServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // 4. 解析响应数据
            let wrapper = try JSONDecoder().decode(JournalDetailResponse.self, from: data)
            print("✅ 日记详情接口 - 成功获取日记详情，ID: \(wrapper.journal.journal_id)")
            
            // 5. 转换为ChatRecord格式
            guard let chatRecord = convertJournalDataToChatRecord(wrapper.journal) else {
                throw JournalDetailServiceError.invalidResponse
            }
            
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
        
        // 缓存到本地，包含缓存时间
        let cacheKey = "journal_detail_\(journalId)"
        let cacheData = CacheData(record: chatRecord, timestamp: Date())
        if let data = try? JSONEncoder().encode(cacheData) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            print("✅ 日记详情已缓存: \(cacheKey)")
        }
        
        return chatRecord
    }
    
    /// 获取日记详情但不缓存（用于强制刷新）
    func fetchJournalDetailWithoutCache(journalId: Int) async throws -> ChatRecord {
        return try await fetchJournalDetail(journalId: journalId)
    }
    
    /// 从本地缓存获取日记详情
    func getCachedJournalDetail(journalId: Int) -> ChatRecord? {
        let cacheKey = "journal_detail_\(journalId)"
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cacheData = try? JSONDecoder().decode(CacheData.self, from: data) else {
            return nil
        }
        
        // 检查缓存是否过期（24小时）
        let cacheAge = Date().timeIntervalSince(cacheData.timestamp)
        let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24小时
        
        if cacheAge > maxCacheAge {
            print("⏰ 缓存已过期，清除: \(cacheKey)")
            clearDetailCache(journalId: journalId)
            return nil
        }
        
        return cacheData.record
    }
    
    /// 检查日记详情是否已缓存
    func isDetailCached(journalId: Int) -> Bool {
        let cacheKey = "journal_detail_\(journalId)"
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cacheData = try? JSONDecoder().decode(CacheData.self, from: data) else {
            return false
        }
        
        // 检查缓存是否过期
        let cacheAge = Date().timeIntervalSince(cacheData.timestamp)
        let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24小时
        
        if cacheAge > maxCacheAge {
            clearDetailCache(journalId: journalId)
            return false
        }
        
        return true
    }
    
    /// 清除日记详情缓存
    func clearDetailCache(journalId: Int) {
        let cacheKey = "journal_detail_\(journalId)"
        UserDefaults.standard.removeObject(forKey: cacheKey)
        print("🗑️ 已清除日记详情缓存: \(cacheKey)")
    }
    
    /// 将后端JournalData转换为前端ChatRecord
    private func convertJournalDataToChatRecord(_ journalData: JournalData) -> ChatRecord? {
        // 由于后端不再返回messages字段，我们需要创建一个空的messages数组
        // 或者通过其他方式获取对话历史
        let messages: [ChatMessage] = []
        
        // 转换时间格式，使用创建时间
        let date = parseBackendTime(journalData.created_at)
        
        // 转换情绪类型（优先使用后端返回的emotion字段）
        let emotion: EmotionType
        if let backendEmotion = journalData.emotion {
            // 使用后端返回的情绪
            emotion = convertBackendEmotionToEmotionType(backendEmotion)
        } else {
            // 如果后端没有返回情绪，从内容中推断
            emotion = inferEmotionFromContent(journalData.content)
        }
        
        // 调试图片数据
        print("🔍 JournalDetailService - 转换日记数据:")
        print("   日记ID: \(journalData.journal_id)")
        print("   图片IDs: \(journalData.images ?? [])")
        print("   图片URLs: \(journalData.image_urls ?? [])")
        
        return ChatRecord(
            id: UUID(), // 前端使用UUID，后端使用Int
            backendId: journalData.journal_id, // 保存后端ID
            date: date, // 使用创建时间
            messages: messages, // 空数组，需要通过历史记录接口获取
            summary: journalData.content, // 使用 content 字段
            emotion: emotion,
            title: nil, // 新格式中没有 title 字段
            originalTimeString: journalData.created_at, // 保存原始时间字符串
            images: journalData.images, // 图片ID列表
            image_urls: journalData.image_urls // 图片URL列表
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
    private func convertBackendEmotionToEmotionType(_ backendEmotion: String) -> EmotionType {
        switch backendEmotion.lowercased() {
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
            print("   ⚠️ 未知的后端情绪类型: \(backendEmotion)，默认使用peaceful")
            return .peaceful
        }
    }
} 