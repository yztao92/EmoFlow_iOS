import Foundation

// MARK: - 响应结构
struct UserHeartResponse: Codable {
    let user: UserHeartData
}

struct UserHeartData: Codable {
    let heart: Int
}

// MARK: - 自定义错误
enum UserHeartServiceError: Error, LocalizedError {
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

// MARK: - UserHeartService 单例
class UserHeartService {
    static let shared = UserHeartService()
    private init() {}
    
    private let url = URL(string: "https://emoflow.net.cn/user/heart")!
    private let timeoutInterval: TimeInterval = 30.0
    
    /// 获取用户最新的心心数量
    func fetchUserHeart() async throws -> Int {
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        
        // 添加认证token - 强制要求token验证
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("❌ 获取心心接口 - 未找到用户token，拒绝发送请求")
            throw UserHeartServiceError.unauthorized
        }
        
        request.addValue(token, forHTTPHeaderField: "token")
        print("🔍 获取心心接口 - 添加认证token: \(token.prefix(10))...")
        
        // 2. 发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 3. 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserHeartServiceError.invalidResponse
            }
            
            print("🔍 获取心心接口 - 后端响应:")
            print("   HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ 获取心心接口 - HTTP错误: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response Body: \(responseString)")
                }
                
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
                    
                    throw UserHeartServiceError.unauthorized
                } else {
                    throw UserHeartServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // 4. 解析响应数据
            print("🔍 获取心心接口 - 解析响应数据:")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Raw Response: \(responseString)")
            }
            
            let wrapper = try JSONDecoder().decode(UserHeartResponse.self, from: data)
            let heartCount = wrapper.user.heart
            print("   Parsed Heart Count: \(heartCount)")
            
            // 5. 更新本地存储的心心值
            UserDefaults.standard.set(heartCount, forKey: "heartCount")
            print("🔍 获取心心接口 - 更新本地心心值: \(heartCount)")
            
            return heartCount
            
        } catch let error as UserHeartServiceError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw UserHeartServiceError.timeout
            } else {
                throw UserHeartServiceError.networkError(error.localizedDescription)
            }
        }
    }
}
