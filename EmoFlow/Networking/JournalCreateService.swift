import Foundation

// MARK: - 日记创建错误枚举
enum JournalCreateServiceError: Error, LocalizedError {
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

// MARK: - 日记创建请求模型
struct JournalCreateRequest: Codable {
    let content: String
    let emotion: String
    let has_image: Bool // 是否有图片
    let image_data: [String]? // Base64编码的图片数据列表
}

// MARK: - 日记创建响应模型
struct JournalCreateResponse: Codable {
    let status: String
    let journal_id: Int
    let content: String
    let emotion: String
    let images: [String]? // 图片ID列表
    let image_urls: [String]? // 图片URL列表
}

// MARK: - 日记创建服务
class JournalCreateService {
    static let shared = JournalCreateService()
    private let baseURL = "https://emoflow.net.cn"
    
    private init() {}
    
    func createJournal(content: String, emotion: EmotionType, imageData: [String]? = nil) async throws -> JournalCreateResponse {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw NetworkError.noToken
        }
        
        let url = URL(string: "\(baseURL)/api/journal/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let hasImage = imageData != nil && !imageData!.isEmpty
        let requestBody = JournalCreateRequest(
            content: content,
            emotion: emotion.rawValue,
            has_image: hasImage,
            image_data: hasImage ? imageData : nil
        )
        
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw NetworkError.encodingError
        }
        
        print("🔍 日记创建接口 - 开始创建")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("🔍 日记创建接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 日记创建接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 日记创建接口 - 错误信息: \(errorMessage)")
            
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
                
                throw JournalCreateServiceError.unauthorized
            } else {
                throw NetworkError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(JournalCreateResponse.self, from: data)
            print("✅ 日记创建接口 - 成功创建日记，ID: \(response.journal_id)")
            return response
        } catch {
            print("❌ 日记创建接口 - 解析响应失败: \(error)")
            throw NetworkError.decodingError
        }
    }
}

// MARK: - 网络错误枚举
enum NetworkError: Error {
    case noToken
    case encodingError
    case invalidResponse
    case httpError(Int, String)
    case decodingError
    case unauthorized
} 