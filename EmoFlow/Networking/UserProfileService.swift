import Foundation

// MARK: - 用户资料更新请求模型
struct UserProfileUpdateRequest: Codable {
    let name: String
    let email: String
    let birthday: String?
    let is_member: Bool
}

// MARK: - 生日更新请求模型
struct BirthdayUpdateRequest: Codable {
    let name: String
    let email: String
    let birthday: String
    let is_member: Bool
}

// MARK: - 用户资料更新响应模型
struct UserProfileUpdateResponse: Codable {
    let status: String
    let message: String
    let user: UserInfo
}

// MARK: - 生日更新响应模型
struct BirthdayUpdateResponse: Codable {
    let status: String
    let message: String
    let user: UserInfo
}

// MARK: - 获取用户信息响应模型
struct UserProfileResponse: Codable {
    let status: String
    let user: UserInfo
}

struct UserInfo: Codable {
    let id: Int
    let name: String
    let email: String
    let heart: Int
    let is_member: Bool
    let birthday: String?
    let membership_expires_at: String?
}

// MARK: - 用户资料服务
class UserProfileService {
    static let shared = UserProfileService()
    private let baseURL = "https://emoflow.net.cn"
    
    private init() {}
    
    /// 获取用户信息
    func fetchUserProfile() async throws -> UserInfo {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw UserProfileError.noToken
        }
        
        let url = URL(string: "\(baseURL)/user/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "token")
        
        print("🔍 获取用户信息接口 - 请求URL: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserProfileError.invalidResponse
        }
        
        print("🔍 获取用户信息接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 获取用户信息接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 获取用户信息接口 - 错误信息: \(errorMessage)")
            
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
                
                throw UserProfileError.unauthorized
            } else {
                throw UserProfileError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(UserProfileResponse.self, from: data)
            print("✅ 获取用户信息接口 - 成功获取用户信息: \(response.user.name)")
            
            // 保存用户信息到本地存储
            UserDefaults.standard.set(response.user.name, forKey: "userName")
            UserDefaults.standard.set(response.user.email, forKey: "userEmail")
            UserDefaults.standard.set(response.user.heart, forKey: "heartCount")
            UserDefaults.standard.set(response.user.birthday, forKey: "userBirthday")
            UserDefaults.standard.set(response.user.is_member, forKey: "isMember")
            
            return response.user
        } catch {
            print("❌ 获取用户信息接口 - 解析响应失败: \(error)")
            throw UserProfileError.decodingError
        }
    }
    
    /// 更新生日
    func updateBirthday(_ newBirthday: String) async throws -> UserInfo {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw UserProfileError.noToken
        }
        
        let url = URL(string: "\(baseURL)/user/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        
        let requestBody = BirthdayUpdateRequest(
            name: UserDefaults.standard.string(forKey: "userName") ?? "",
            email: UserDefaults.standard.string(forKey: "userEmail") ?? "",
            birthday: newBirthday,
            is_member: UserDefaults.standard.bool(forKey: "isMember")
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw UserProfileError.encodingError
        }
        
        print("🔍 生日更新接口 - 请求URL: \(url)")
        print("🔍 生日更新接口 - 新生日: \(newBirthday)")
        print("🔍 生日更新接口 - 发送的完整信息: \(requestBody)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserProfileError.invalidResponse
        }
        
        print("🔍 生日更新接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 生日更新接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 生日更新接口 - 错误信息: \(errorMessage)")
            
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
                
                throw UserProfileError.unauthorized
            } else {
                throw UserProfileError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(BirthdayUpdateResponse.self, from: data)
            print("✅ 生日更新接口 - 成功更新生日: \(response.user.birthday ?? "未设置")")
            
            // 保存更新后的用户信息到本地存储
            UserDefaults.standard.set(response.user.name, forKey: "userName")
            UserDefaults.standard.set(response.user.email, forKey: "userEmail")
            UserDefaults.standard.set(response.user.heart, forKey: "heartCount")
            UserDefaults.standard.set(response.user.birthday, forKey: "userBirthday")
            UserDefaults.standard.set(response.user.is_member, forKey: "isMember")
            
            return response.user
        } catch {
            print("❌ 生日更新接口 - 解析响应失败: \(error)")
            throw UserProfileError.decodingError
        }
    }
    
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
        
        let requestBody = UserProfileUpdateRequest(
            name: newName,
            email: UserDefaults.standard.string(forKey: "userEmail") ?? "",
            birthday: UserDefaults.standard.string(forKey: "userBirthday"),
            is_member: UserDefaults.standard.bool(forKey: "isMember")
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw UserProfileError.encodingError
        }
        
        print("🔍 用户名更新接口 - 请求URL: \(url)")
        print("🔍 用户名更新接口 - 新用户名: \(newName)")
        print("🔍 用户名更新接口 - 发送的完整信息: \(requestBody)")
        
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
                UserDefaults.standard.removeObject(forKey: "heartCount")
                UserDefaults.standard.removeObject(forKey: "userBirthday")
                UserDefaults.standard.removeObject(forKey: "isMember")
                
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
            
            // 保存更新后的用户信息到本地存储
            UserDefaults.standard.set(response.user.name, forKey: "userName")
            UserDefaults.standard.set(response.user.email, forKey: "userEmail")
            UserDefaults.standard.set(response.user.heart, forKey: "heartCount")
            UserDefaults.standard.set(response.user.birthday, forKey: "userBirthday")
            UserDefaults.standard.set(response.user.is_member, forKey: "isMember")
            
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