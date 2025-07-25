//
//  JournalDeleteService.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/1/27.
//

import Foundation

// MARK: - 响应结构
struct JournalDeleteResponse: Codable {
    let status: String
    let message: String
}

// MARK: - 自定义错误
enum JournalDeleteServiceError: Error, LocalizedError {
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

// MARK: - JournalDeleteService 单例
class JournalDeleteService {
    static let shared = JournalDeleteService()
    private init() {}
    
    private let baseURL = "https://emoflow.net.cn/journal/"
    private let timeoutInterval: TimeInterval = 30.0
    
    /// 删除日记
    func deleteJournal(journalId: Int) async throws -> Bool {
        guard let url = URL(string: baseURL + "\(journalId)") else {
            throw JournalDeleteServiceError.invalidResponse
        }
        
        // 1. 构造 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = timeoutInterval
        
        // 添加认证token
        if let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty {
            request.addValue(token, forHTTPHeaderField: "token")
            print("🔍 日记删除接口 - 添加认证token: \(token.prefix(10))...")
        } else {
            print("⚠️ 日记删除接口 - 未找到用户token")
            throw JournalDeleteServiceError.unauthorized
        }
        
        print("🔍 日记删除接口 - 请求URL: \(request.url?.absoluteString ?? "")")
        
        // 2. 发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 3. 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JournalDeleteServiceError.invalidResponse
            }
            
            print("🔍 日记删除接口 - 后端响应:")
            print("   HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ 日记删除接口 - HTTP错误: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response Body: \(responseString)")
                }
                
                if httpResponse.statusCode == 401 {
                    throw JournalDeleteServiceError.unauthorized
                } else if httpResponse.statusCode == 404 {
                    throw JournalDeleteServiceError.notFound
                } else {
                    throw JournalDeleteServiceError.networkError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // 4. 解析响应数据
            print("🔍 日记删除接口 - 解析响应数据:")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Raw Response: \(responseString)")
            }
            
            let wrapper = try JSONDecoder().decode(JournalDeleteResponse.self, from: data)
            print("   Parsed Status: \(wrapper.status)")
            print("   Parsed Message: \(wrapper.message)")
            
            // 5. 检查删除结果
            guard wrapper.status == "success" else {
                throw JournalDeleteServiceError.networkError("删除失败: \(wrapper.message)")
            }
            
            print("✅ 日记删除接口 - 成功删除日记")
            
            // 6. 清除本地缓存
            JournalDetailService.shared.clearDetailCache(journalId: journalId)
            
            return true
            
        } catch let error as JournalDeleteServiceError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw JournalDeleteServiceError.timeout
            } else {
                throw JournalDeleteServiceError.networkError(error.localizedDescription)
            }
        }
    }
} 