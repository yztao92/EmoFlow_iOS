import Foundation

// MARK: - 订阅产品数据模型
struct SubscriptionProduct: Codable, Identifiable {
    let id: String
    let name: String
    let price: String
    let daily_price: String
    let period: String
    let period_display: String
    let apple_product_id: String
    let is_popular: Bool?
    let sort_order: Int?
}

// MARK: - 购买验证请求模型
struct PurchaseVerifyRequest: Codable {
    let receipt_data: String
}

// MARK: - 订阅详情模型
struct SubscriptionDetail: Codable {
    let status: String
    let product_id: String
    let expires_at: String
    let auto_renew: Bool
    let environment: String?
    let is_member: Bool?
}

// MARK: - 订阅状态模型（用于GET /subscription/status）
struct SubscriptionStatus: Codable {
    let subscription_status: String
    let subscription_product_id: String
    let subscription_expires_at: String
    let auto_renew_status: Bool
    let subscription_environment: String?
    let is_member: Bool
}

// MARK: - 订阅状态响应模型（用于GET /subscription/status）
struct SubscriptionStatusResponse: Codable {
    let status: String
    let subscription: SubscriptionStatus
}

// MARK: - 购买验证响应模型（用于POST /subscription/verify）
struct PurchaseVerifyResponse: Codable {
    let status: String
    let message: String
    let subscription: SubscriptionDetail
}

// MARK: - 刷新订阅响应模型（用于POST /subscription/refresh）
struct SubscriptionRefreshResponse: Codable {
    let status: String
    let message: String
    let subscription: SubscriptionDetail
}

// MARK: - 恢复购买响应模型（用于POST /subscription/restore）
struct SubscriptionRestoreResponse: Codable {
    let status: String
    let message: String
    let subscription: SubscriptionDetail
}

// MARK: - 订阅产品列表响应模型
struct SubscriptionProductsResponse: Codable {
    let status: String
    let message: String
    let products: [SubscriptionProduct]
}

// MARK: - 订阅服务
class SubscriptionService {
    static let shared = SubscriptionService()
    private let baseURL = "https://emoflow.net.cn"
    
    private init() {}
    
    /// 获取订阅产品列表
    func fetchSubscriptionProducts() async throws -> [SubscriptionProduct] {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw SubscriptionError.noToken
        }
        
        let url = URL(string: "\(baseURL)/subscription/products")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "token")
        
        print("🔍 获取订阅产品列表接口 - 开始请求")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }
        
        print("🔍 获取订阅产品列表接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 获取订阅产品列表接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 获取订阅产品列表接口 - 错误信息: \(errorMessage)")
            
            // 添加 401 特殊处理
            if httpResponse.statusCode == 401 {
                // 清除本地 token
                UserDefaults.standard.removeObject(forKey: "userToken")
                UserDefaults.standard.removeObject(forKey: "userName")
                UserDefaults.standard.removeObject(forKey: "userEmail")
                UserDefaults.standard.removeObject(forKey: "heartCount")
                UserDefaults.standard.removeObject(forKey: "userBirthday")
                UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
                UserDefaults.standard.removeObject(forKey: "subscriptionExpiresAt")
                
                // 发送登出通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .logout, object: nil)
                }
                
                throw SubscriptionError.unauthorized
            } else {
                throw SubscriptionError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(SubscriptionProductsResponse.self, from: data)
            print("✅ 获取订阅产品列表接口 - 成功获取 \(response.products.count) 个产品")
            
            // 按 sort_order 排序
            let sortedProducts = response.products.sorted { product1, product2 in
                let order1 = product1.sort_order ?? Int.max
                let order2 = product2.sort_order ?? Int.max
                return order1 < order2
            }
            
            return sortedProducts
        } catch {
            print("❌ 获取订阅产品列表接口 - 解析响应失败: \(error)")
            throw SubscriptionError.decodingError
        }
    }
    
    /// 验证购买收据
    func verifyPurchase(receiptData: String) async throws -> SubscriptionDetail {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw SubscriptionError.noToken
        }
        
        let url = URL(string: "\(baseURL)/subscription/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        
        let requestBody = PurchaseVerifyRequest(
            receipt_data: receiptData
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw SubscriptionError.encodingError
        }
        
        print("🔍 验证购买收据接口 - 开始请求")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }
        
        print("🔍 验证购买收据接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 验证购买收据接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 验证购买收据接口 - 错误信息: \(errorMessage)")
            
            if httpResponse.statusCode == 401 {
                // 清除本地 token
                UserDefaults.standard.removeObject(forKey: "userToken")
                UserDefaults.standard.removeObject(forKey: "userName")
                UserDefaults.standard.removeObject(forKey: "userEmail")
                UserDefaults.standard.removeObject(forKey: "heartCount")
                UserDefaults.standard.removeObject(forKey: "userBirthday")
                UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
                UserDefaults.standard.removeObject(forKey: "subscriptionExpiresAt")
                
                // 发送登出通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .logout, object: nil)
                }
                
                throw SubscriptionError.unauthorized
            } else {
                throw SubscriptionError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(PurchaseVerifyResponse.self, from: data)
            print("✅ 验证购买收据接口 - 验证成功")
            
            // 保存订阅状态到本地存储
            let subscription = response.subscription
            UserDefaults.standard.set(subscription.status, forKey: "subscriptionStatus")
            UserDefaults.standard.set(subscription.expires_at, forKey: "subscriptionExpiresAt")
            
            return subscription
        } catch {
            print("❌ 验证购买收据接口 - 解析响应失败: \(error)")
            throw SubscriptionError.decodingError
        }
    }
    
    /// 查询订阅状态
    func fetchSubscriptionStatus() async throws -> SubscriptionStatus {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw SubscriptionError.noToken
        }
        
        let url = URL(string: "\(baseURL)/subscription/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "token")
        
        print("🔍 查询订阅状态接口 - 开始请求")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }
        
        print("🔍 查询订阅状态接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 查询订阅状态接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 查询订阅状态接口 - 错误信息: \(errorMessage)")
            
            if httpResponse.statusCode == 401 {
                // 清除本地 token
                UserDefaults.standard.removeObject(forKey: "userToken")
                UserDefaults.standard.removeObject(forKey: "userName")
                UserDefaults.standard.removeObject(forKey: "userEmail")
                UserDefaults.standard.removeObject(forKey: "heartCount")
                UserDefaults.standard.removeObject(forKey: "userBirthday")
                UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
                UserDefaults.standard.removeObject(forKey: "subscriptionExpiresAt")
                
                // 发送登出通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .logout, object: nil)
                }
                
                throw SubscriptionError.unauthorized
            } else {
                throw SubscriptionError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(SubscriptionStatusResponse.self, from: data)
            print("✅ 查询订阅状态接口 - 查询成功")
            
            // 保存订阅状态到本地存储
            let subscription = response.subscription
            UserDefaults.standard.set(subscription.subscription_status, forKey: "subscriptionStatus")
            UserDefaults.standard.set(subscription.subscription_expires_at, forKey: "subscriptionExpiresAt")
            
            return subscription
        } catch {
            print("❌ 查询订阅状态接口 - 解析响应失败: \(error)")
            throw SubscriptionError.decodingError
        }
    }
    
    /// 刷新订阅状态
    func refreshSubscriptionStatus() async throws -> SubscriptionDetail {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw SubscriptionError.noToken
        }
        
        let url = URL(string: "\(baseURL)/subscription/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "token")
        
        print("🔍 刷新订阅状态接口 - 开始请求")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }
        
        print("🔍 刷新订阅状态接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 刷新订阅状态接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 刷新订阅状态接口 - 错误信息: \(errorMessage)")
            
            if httpResponse.statusCode == 401 {
                // 清除本地 token
                UserDefaults.standard.removeObject(forKey: "userToken")
                UserDefaults.standard.removeObject(forKey: "userName")
                UserDefaults.standard.removeObject(forKey: "userEmail")
                UserDefaults.standard.removeObject(forKey: "heartCount")
                UserDefaults.standard.removeObject(forKey: "userBirthday")
                UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
                UserDefaults.standard.removeObject(forKey: "subscriptionExpiresAt")
                
                // 发送登出通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .logout, object: nil)
                }
                
                throw SubscriptionError.unauthorized
            } else {
                throw SubscriptionError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(SubscriptionRefreshResponse.self, from: data)
            print("✅ 刷新订阅状态接口 - 刷新成功")
            
            // 保存订阅状态到本地存储
            let subscription = response.subscription
            UserDefaults.standard.set(subscription.status, forKey: "subscriptionStatus")
            UserDefaults.standard.set(subscription.expires_at, forKey: "subscriptionExpiresAt")
            
            return subscription
        } catch {
            print("❌ 刷新订阅状态接口 - 解析响应失败: \(error)")
            throw SubscriptionError.decodingError
        }
    }
    
    /// 恢复订阅购买
    func restoreSubscription(receiptData: String) async throws -> SubscriptionDetail {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw SubscriptionError.noToken
        }
        
        let url = URL(string: "\(baseURL)/subscription/restore")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        
        let requestBody = ["receipt_data": receiptData]
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw SubscriptionError.encodingError
        }
        
        print("🔍 恢复订阅购买接口 - 开始请求")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }
        
        print("🔍 恢复订阅购买接口 - HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 恢复订阅购买接口 - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 恢复订阅购买接口 - 错误信息: \(errorMessage)")
            
            if httpResponse.statusCode == 401 {
                // 清除本地 token
                UserDefaults.standard.removeObject(forKey: "userToken")
                UserDefaults.standard.removeObject(forKey: "userName")
                UserDefaults.standard.removeObject(forKey: "userEmail")
                UserDefaults.standard.removeObject(forKey: "heartCount")
                UserDefaults.standard.removeObject(forKey: "userBirthday")
                UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
                UserDefaults.standard.removeObject(forKey: "subscriptionExpiresAt")
                
                // 发送登出通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .logout, object: nil)
                }
                
                throw SubscriptionError.unauthorized
            } else {
                throw SubscriptionError.httpError(httpResponse.statusCode, errorMessage)
            }
        }
        
        do {
            let response = try JSONDecoder().decode(SubscriptionRestoreResponse.self, from: data)
            print("✅ 恢复订阅购买接口 - 恢复成功")
            
            // 保存订阅状态到本地存储
            let subscription = response.subscription
            UserDefaults.standard.set(subscription.status, forKey: "subscriptionStatus")
            UserDefaults.standard.set(subscription.expires_at, forKey: "subscriptionExpiresAt")
            
            return subscription
        } catch {
            print("❌ 恢复订阅购买接口 - 解析响应失败: \(error)")
            throw SubscriptionError.decodingError
        }
    }
}

// MARK: - 订阅错误枚举
enum SubscriptionError: Error, LocalizedError {
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
