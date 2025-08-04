import Foundation

// MARK: - 日记创建请求模型
struct JournalCreateRequest: Codable {
    let title: String
    let content: String
    let emotion: String
}

// MARK: - 日记创建响应模型
struct JournalCreateResponse: Codable {
    let status: String
    let journal_id: Int
    let title: String
    let content: String
    let emotion: String
}

// MARK: - 日记创建服务
class JournalCreateService {
    static let shared = JournalCreateService()
    private let baseURL = "https://emoflow.net.cn"
    
    private init() {}
    
    func createJournal(title: String, content: String, emotion: EmotionType) async throws -> JournalCreateResponse {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw NetworkError.noToken
        }
        
        let url = URL(string: "\(baseURL)/journal/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        
        let requestBody = JournalCreateRequest(
            title: title,
            content: content,
            emotion: emotion.rawValue
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw NetworkError.encodingError
        }
        
        print("🔍 日记创建接口 - 请求URL: \(url)")
        print("🔍 日记创建接口 - 请求数据: \(requestBody)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("🔍 日记创建接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 日记创建接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 日记创建接口 - 错误信息: \(errorMessage)")
            throw NetworkError.httpError(httpResponse.statusCode, errorMessage)
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
} 