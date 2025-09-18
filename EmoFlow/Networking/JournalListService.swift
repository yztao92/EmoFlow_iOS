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
    let data: JournalListData
}

struct JournalListData: Codable {
    let journals: [JournalData]
    let total: Int
    let page: Int
    let limit: Int
}


struct JournalData: Codable {
    let journal_id: Int  // 后端返回的是 journal_id
    let content: String  // 日记内容
    let emotion: String?
    let images: [String]?  // 图片ID列表
    let image_urls: [String]?  // 图片URL列表
    let created_at: String?
    
    enum CodingKeys: String, CodingKey {
        case journal_id, content, emotion, created_at
        case images, image_urls
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
        print("🔍 JournalListService - 开始获取日记列表")
        
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        
        // 添加认证token
        if let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty {
            request.addValue(token, forHTTPHeaderField: "token")
            print("   ✅ 已添加认证token")
        } else {
            print("   ❌ 未找到用户token")
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
            
            print("   📡 HTTP状态码: \(httpResponse.statusCode)")
            
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
                
                throw JournalListServiceError.unauthorized
            } else {
                guard httpResponse.statusCode == 200 else {
                    throw JournalListServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // 4. 解析响应数据
            do {
                let wrapper = try JSONDecoder().decode(JournalListResponse.self, from: data)
                print("   📊 后端返回日记数量: \(wrapper.data.journals.count)")
                
                // 5. 转换为ChatRecord格式
                let chatRecords = wrapper.data.journals.compactMap { journalData -> ChatRecord? in
                    return convertJournalDataToChatRecord(journalData)
                }
                
                print("   ✅ 成功转换 \(chatRecords.count) 条日记记录")
                return chatRecords
                
            } catch {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   ❌ 原始响应: \(responseString)")
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
        print("🔄 JournalListService - 开始同步日记列表")
        do {
            let journals = try await fetchJournals(limit: 100, offset: 0) // 获取更多数据
            print("   ✅ 从后端获取到 \(journals.count) 条日记")
            
            RecordManager.saveAll(journals)
            print("   ✅ 已保存到本地缓存")
            
            print("✅ 日记列表同步成功")
        } catch {
            print("❌ 日记列表同步失败: \(error)")
        }
    }
    
    
    /// 将后端JournalData转换为前端ChatRecord
    private func convertJournalDataToChatRecord(_ journalData: JournalData) -> ChatRecord? {
        // 由于后端不再返回messages字段，我们需要创建一个空的messages数组
        // 或者通过其他方式获取对话历史
        let messages: [ChatMessage] = []
        
        // 使用创建时间作为主要时间
        let createdDate = parseBackendTime(journalData.created_at)
        
        // 转换情绪类型（从后端emotion字段获取）
        let emotion = convertBackendEmotionToEmotionType(journalData.emotion)
        
        // 使用 content 作为主要内容，memory_point 作为摘要
        let summaryContent = journalData.content
        
        // 调试图片数据
        print("🔍 JournalListService - 转换日记数据:")
        print("   日记ID: \(journalData.journal_id)")
        print("   图片IDs: \(journalData.images ?? [])")
        print("   图片URLs: \(journalData.image_urls ?? [])")
        
        let chatRecord = ChatRecord(
            id: UUID(), // 前端使用UUID，后端使用Int
            backendId: journalData.journal_id, // 保存后端ID
            date: createdDate, // 使用创建时间
            messages: messages, // 空数组，需要通过历史记录接口获取
            summary: summaryContent, // 使用 content 字段
            emotion: emotion,
            title: nil, // 新格式中没有 title 字段
            originalTimeString: journalData.created_at, // 保存原始时间字符串
            images: journalData.images, // 图片ID列表
            image_urls: journalData.image_urls // 图片URL列表
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