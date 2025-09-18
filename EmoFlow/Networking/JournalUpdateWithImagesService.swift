import Foundation

// 更新日记请求结构
struct UpdateJournalRequest: Codable {
    let content: String?
    let emotion: String?
    let has_image: Bool
    let keep_image_ids: [Int]?
    let add_image_data: [String]?
}

// 更新日记响应结构
struct UpdateJournalResponse: Codable {
    let status: String
    let journal_id: Int
    let content: String
    let emotion: String
    let images: [String]?
    let image_urls: [String]?
    let updated_fields: [String]?
    let message: String
}

// 创建日记请求结构
struct CreateJournalRequest: Codable {
    let content: String
    let emotion: String?
    let has_image: Bool
    let image_data: [String]?
}

// 创建日记响应结构
struct CreateJournalResponse: Codable {
    let journal_id: Int
    let content: String
    let emotion: String
    let images: [String]?
    let image_urls: [String]?
    let status: String
}

class JournalUpdateWithImagesService {
    static let shared = JournalUpdateWithImagesService()
    private init() {}
    
    private let baseURL = "https://emoflow.net.cn"
    
    // 更新日记
    func updateJournal(
        journalId: Int,
        content: String?,
        emotion: EmotionType?,
        keepImageIds: [Int] = [],
        addImageData: [String] = []
    ) async throws -> UpdateJournalResponse {
        
        guard let url = URL(string: "\(baseURL)/journal/\(journalId)") else {
            throw NetworkError.invalidResponse
        }
        
        // 获取JWT token
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("❌ 日记更新接口（支持图片） - 未找到用户Token")
            throw NetworkError.unauthorized
        }
        
        print("🔍 日记更新接口（支持图片） - 找到用户Token: \(token.prefix(20))...")
        
        let hasImage = !keepImageIds.isEmpty || !addImageData.isEmpty
        
        let request = UpdateJournalRequest(
            content: content,
            emotion: emotion?.rawValue,
            has_image: hasImage,
            keep_image_ids: keepImageIds.isEmpty ? nil : keepImageIds,
            add_image_data: addImageData.isEmpty ? nil : addImageData
        )
        
        print("🔍 日记更新接口（支持图片） - 请求URL: \(url)")
        print("🔍 日记更新接口（支持图片） - 请求数据: \(request)")
        
        // 打印详细的请求体信息
        if let requestBody = try? JSONEncoder().encode(request),
           let requestBodyString = String(data: requestBody, encoding: .utf8) {
            print("🔍 日记更新接口（支持图片） - 请求体JSON: \(requestBodyString)")
        }
        
        // 打印keep_image_ids的具体类型和内容
        if let keepImageIds = request.keep_image_ids {
            print("🔍 日记更新接口（支持图片） - keep_image_ids类型: \(type(of: keepImageIds))")
            print("🔍 日记更新接口（支持图片） - keep_image_ids内容: \(keepImageIds)")
            print("🔍 日记更新接口（支持图片） - keep_image_ids元素类型: \(keepImageIds.map { type(of: $0) })")
        } else {
            print("🔍 日记更新接口（支持图片） - keep_image_ids为nil")
        }
        
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.setValue(token, forHTTPHeaderField: "token")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.timeoutInterval = 30

            // 打印请求头信息
            print("🔍 日记更新接口（支持图片） - 请求头:")
            print("   token: \(token)")
            print("   Content-Type: application/json")
            print("   HTTP Method: PUT")
            print("   URL: \(url)")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // 打印详细的错误信息
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 日记更新接口（支持图片） - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 日记更新接口（支持图片） - 错误信息: \(errorMessage)")
            print("❌ 日记更新接口（支持图片） - 请求数据: \(request)")
            
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            } else if httpResponse.statusCode == 404 {
                throw NetworkError.invalidResponse
            } else if httpResponse.statusCode == 422 {
                // 422 表示数据验证失败，可能是数据类型不匹配
                print("❌ 数据验证失败 (422) - 请检查请求数据格式")
                throw NetworkError.invalidResponse
            } else {
                throw NetworkError.invalidResponse
            }
        }
        
        do {
            let updateResponse = try JSONDecoder().decode(UpdateJournalResponse.self, from: data)
            print("✅ 日记更新接口（支持图片） - 成功更新日记，ID: \(updateResponse.journal_id)")
            print("✅ 日记更新接口（支持图片） - 更新字段: \(updateResponse.updated_fields ?? [])")
            print("✅ 日记更新接口（支持图片） - 消息: \(updateResponse.message)")
            return updateResponse
        } catch {
            print("❌ 日记更新接口（支持图片） - 解析响应失败: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    // 创建日记
    func createJournal(
        content: String,
        emotion: EmotionType?,
        imageData: [String] = []
    ) async throws -> CreateJournalResponse {
        
        guard let url = URL(string: "\(baseURL)/api/journal/create") else {
            throw NetworkError.invalidResponse
        }
        
        // 获取JWT token
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw NetworkError.unauthorized
        }
        
        let hasImage = !imageData.isEmpty
        
        let request = CreateJournalRequest(
            content: content,
            emotion: emotion?.rawValue,
            has_image: hasImage,
            image_data: imageData.isEmpty ? nil : imageData
        )
        
        // 打印详细的请求体信息
        print("🔍 日记创建接口（支持图片） - 请求URL: \(url)")
        print("🔍 日记创建接口（支持图片） - 请求数据: \(request)")
        
        if let requestBody = try? JSONEncoder().encode(request),
           let requestBodyString = String(data: requestBody, encoding: .utf8) {
            print("🔍 日记创建接口（支持图片） - 请求体JSON: \(requestBodyString)")
        }
        
        // 打印image_data的具体类型和内容
        if let imageData = request.image_data {
            print("🔍 日记创建接口（支持图片） - image_data类型: \(type(of: imageData))")
            print("🔍 日记创建接口（支持图片） - image_data数量: \(imageData.count)")
            print("🔍 日记创建接口（支持图片） - image_data元素类型: \(imageData.map { type(of: $0) })")
        } else {
            print("🔍 日记创建接口（支持图片） - image_data为nil")
        }
        
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue(token, forHTTPHeaderField: "token")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.timeoutInterval = 30
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // 打印详细的错误信息
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 日记创建接口（支持图片） - HTTP错误: \(httpResponse.statusCode)")
            print("❌ 日记创建接口（支持图片） - 错误信息: \(errorMessage)")
            print("❌ 日记创建接口（支持图片） - 请求数据: \(request)")
            
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            } else if httpResponse.statusCode == 404 {
                throw NetworkError.invalidResponse
            } else if httpResponse.statusCode == 422 {
                // 422 表示数据验证失败，可能是数据类型不匹配
                print("❌ 数据验证失败 (422) - 请检查请求数据格式")
                throw NetworkError.invalidResponse
            } else {
                throw NetworkError.invalidResponse
            }
        }
        
        do {
            let createResponse = try JSONDecoder().decode(CreateJournalResponse.self, from: data)
            return createResponse
        } catch {
            throw NetworkError.decodingError
        }
    }
}
