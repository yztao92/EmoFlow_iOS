//
//  ImageService.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/1/27.
//

import Foundation
import UIKit

class ImageService {
    static let shared = ImageService()
    private init() {}
    
    private let baseURL = "https://emoflow.net.cn"
    private var imageCache: [String: UIImage] = [:]
    
    /// 加载图片
    func loadImage(from urlString: String) async throws -> UIImage {
        // 检查缓存
        if let cachedImage = imageCache[urlString] {
            return cachedImage
        }
        
        // 构建完整URL
        let fullURL: String
        if urlString.hasPrefix("http") {
            fullURL = urlString
        } else if urlString.hasPrefix("/api/") {
            // 如果已经是 /api/ 开头的相对路径，直接拼接
            fullURL = baseURL + urlString
        } else {
            // 如果是其他格式，可能需要特殊处理
            fullURL = baseURL + "/api/images/" + urlString
        }
        
        guard let url = URL(string: fullURL) else {
            throw ImageServiceError.invalidURL
        }
        
        // 获取JWT token
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw ImageServiceError.unauthorized
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw ImageServiceError.unauthorized
            } else if httpResponse.statusCode == 404 {
                throw ImageServiceError.notFound
            } else {
                throw ImageServiceError.networkError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        // 创建图片
        guard let image = UIImage(data: data) else {
            throw ImageServiceError.invalidImageData
        }
        
        // 缓存图片
        imageCache[urlString] = image
        
        return image
    }
    
    /// 清除缓存
    func clearCache() {
        imageCache.removeAll()
    }
}

// MARK: - 错误类型
enum ImageServiceError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case networkError(String)
    case invalidResponse
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的图片URL"
        case .unauthorized:
            return "未授权，请重新登录"
        case .notFound:
            return "图片不存在"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidResponse:
            return "服务器响应格式错误"
        case .invalidImageData:
            return "图片数据格式错误"
        }
    }
}
