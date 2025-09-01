import Foundation

// MARK: - 日记更新错误枚举
enum JournalUpdateServiceError: Error, LocalizedError {
    case unauthorized
    case networkError(String)
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "用户未授权，请重新登录"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidResponse:
            return "服务器响应无效"
        case .decodingError:
            return "响应解析失败"
        }
    }
}

// MARK: - 日记更新请求模型
struct JournalUpdateRequest: Codable {
    let title: String?
    let content: String?
    let emotion: String?
}

// MARK: - 日记更新响应模型
struct JournalUpdateResponse: Codable {
    let status: String
    let journal_id: Int
    let title: String
    let content: String
    let emotion: String
    let updated_fields: [String]
    let message: String
}

// MARK: - 日记更新服务
class JournalUpdateService {
    static let shared = JournalUpdateService()
    private let baseURL = "https://emoflow.net.cn"
    
    private init() {}
    
    func updateJournal(journalId: Int, title: String, content: String, emotion: EmotionType) async throws -> JournalUpdateResponse {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw NetworkError.noToken
        }
        
        let url = URL(string: "\(baseURL)/journal/\(journalId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        
        let requestBody = JournalUpdateRequest(
            title: title,
            content: content,
            emotion: emotion.rawValue
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw NetworkError.encodingError
        }
        
        print("🔍 日记更新接口 - 请求URL: \(url)")
        print("🔍 日记更新接口 - 请求数据: \(requestBody)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("🔍 日记更新接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 日记更新接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 日记更新接口 - 错误信息: \(errorMessage)")
            
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
                
                throw JournalUpdateServiceError.unauthorized
            } else {
                throw NetworkError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(JournalUpdateResponse.self, from: data)
            print("✅ 日记更新接口 - 成功更新日记，ID: \(response.journal_id)")
            print("✅ 日记更新接口 - 更新字段: \(response.updated_fields)")
            print("✅ 日记更新接口 - 消息: \(response.message)")
            
            // 清除对应的详情缓存，确保下次访问时获取最新数据
            JournalDetailService.shared.clearDetailCache(journalId: journalId)
            print("🗑️ 已清除日记详情缓存: journal_\(journalId)")
            
            return response
        } catch {
            print("❌ 日记更新接口 - 解析响应失败: \(error)")
            throw NetworkError.decodingError
        }
    }
} 