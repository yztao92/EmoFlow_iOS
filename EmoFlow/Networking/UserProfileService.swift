import Foundation

// MARK: - 用户资料更新请求模型
struct UserProfileUpdateRequest: Codable {
    let name: String
}

// MARK: - 用户资料更新响应模型
struct UserProfileUpdateResponse: Codable {
    let status: String
    let message: String
    let user: UserInfo
}

struct UserInfo: Codable {
    let id: Int
    let name: String
    let email: String
}

// MARK: - 用户资料更新服务
class UserProfileService {
    static let shared = UserProfileService()
    private let baseURL = "https://emoflow.net.cn"
    
    private init() {}
    
    /// 更新用户名
    func updateUserName(_ newName: String) async throws -> UserInfo {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw UserProfileError.noToken
        }
        
        let url = URL(string: "\(baseURL)/user/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        
        let requestBody = UserProfileUpdateRequest(name: newName)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw UserProfileError.encodingError
        }
        
        print("🔍 用户名更新接口 - 请求URL: \(url)")
        print("🔍 用户名更新接口 - 新用户名: \(newName)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserProfileError.invalidResponse
        }
        
        print("🔍 用户名更新接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 用户名更新接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 用户名更新接口 - 错误信息: \(errorMessage)")
            
            // 添加 401 特殊处理
            if httpResponse.statusCode == 401 {
                // 清除本地 token
                UserDefaults.standard.removeObject(forKey: "userToken")
                UserDefaults.standard.removeObject(forKey: "userName")
                UserDefaults.standard.removeObject(forKey: "userEmail")
                
                // 发送登出通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .logout, object: nil)
                }
                
                throw UserProfileError.unauthorized
            } else {
                throw UserProfileError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(UserProfileUpdateResponse.self, from: data)
            print("✅ 用户名更新接口 - 成功更新用户名: \(response.user.name)")
            return response.user
        } catch {
            print("❌ 用户名更新接口 - 解析响应失败: \(error)")
            throw UserProfileError.decodingError
        }
    }
}

// MARK: - 用户资料错误枚举
enum UserProfileError: Error, LocalizedError {
    case noToken
    case encodingError
    case invalidResponse
    case httpError(Int, String)
    case decodingError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .noToken:
            return "用户未登录"
        case .encodingError:
            return "数据编码失败"
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let code, let message):
            return "网络错误 (\(code)): \(message)"
        case .decodingError:
            return "响应解析失败"
        case .unauthorized:
            return "用户未授权，请重新登录"
        }
    }
} 