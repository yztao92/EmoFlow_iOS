// ChatRecord.swift
import Foundation
import SwiftUI
import UIKit

class ChatRecord: ObservableObject, Identifiable, Codable, Equatable, Hashable {
    static func == (lhs: ChatRecord, rhs: ChatRecord) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    @Published var id: UUID
    @Published var backendId: Int?  // 新增：后端ID
    @Published var date: Date
    @Published var messages: [ChatMessage]
    @Published var summary: String
    @Published var emotion: EmotionType?
    @Published var title: String?  // 新增：日记标题
    @Published var isEdited: Bool = false // 新增：是否被编辑过
    @Published var originalTimeString: String? // 新增：原始时间字符串
    @Published var images: [String]? // 新增：图片ID列表
    @Published var image_urls: [String]? // 新增：图片URL列表

    var safeEmotion: EmotionType { emotion ?? .happy }
    
    /// 获取纯文本内容
    var plainTextContent: String {
        // 直接返回summary，允许为空内容
        return summary
    }
    
    /// 获取HTML格式的内容
    var htmlContent: String {
        return summary.isHTML ? summary : summary.toBasicHTML()
    }
    
    /// 检查内容是否包含HTML标签
    var isHTMLContent: Bool {
        return summary.contains("<") && summary.contains(">")
    }

    enum CodingKeys: String, CodingKey {
        case id, backendId, date, messages, summary, emotion, title, isEdited, originalTimeString, images, image_urls
    }

    init(id: UUID, backendId: Int? = nil, date: Date, messages: [ChatMessage], summary: String, emotion: EmotionType?, title: String? = nil, isEdited: Bool = false, originalTimeString: String? = nil, images: [String]? = nil, image_urls: [String]? = nil) {
        self.id = id
        self.backendId = backendId
        self.date = date
        self.messages = messages
        self.summary = summary
        self.emotion = emotion
        self.title = title
        self.isEdited = isEdited
        self.originalTimeString = originalTimeString
        self.images = images
        self.image_urls = image_urls
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let backendId = try container.decodeIfPresent(Int.self, forKey: .backendId)
        let date = try container.decode(Date.self, forKey: .date)
        let messages = try container.decode([ChatMessage].self, forKey: .messages)
        let summary = try container.decode(String.self, forKey: .summary)
        let emotion = try container.decodeIfPresent(EmotionType.self, forKey: .emotion)
        let title = try container.decodeIfPresent(String.self, forKey: .title)
        let isEdited = try container.decodeIfPresent(Bool.self, forKey: .isEdited) ?? false
        let originalTimeString = try container.decodeIfPresent(String.self, forKey: .originalTimeString)
        let images = try container.decodeIfPresent([String].self, forKey: .images)
        let image_urls = try container.decodeIfPresent([String].self, forKey: .image_urls)
        self.init(id: id, backendId: backendId, date: date, messages: messages, summary: summary, emotion: emotion, title: title, isEdited: isEdited, originalTimeString: originalTimeString, images: images, image_urls: image_urls)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(backendId, forKey: .backendId)
        try container.encode(date, forKey: .date)
        try container.encode(messages, forKey: .messages)
        try container.encode(summary, forKey: .summary)
        try container.encode(emotion, forKey: .emotion)
        try container.encode(title, forKey: .title)
        try container.encode(isEdited, forKey: .isEdited)
        try container.encodeIfPresent(originalTimeString, forKey: .originalTimeString)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(image_urls, forKey: .image_urls)
    }
}

// MARK: - String HTML扩展
extension String {
    /// 将HTML转换为纯文本
    func htmlToString() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("❌ HTML转换失败: \(error)")
            // 如果转换失败，尝试简单的标签移除
            return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&amp;", with: "&")
        }
    }
    
    /// 将纯文本转换为基础HTML
    func toBasicHTML() -> String {
        // 简单的HTML包装，保持换行
        let escapedText = self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        
        return "<p>\(escapedText)</p>"
    }
    
    /// 检查是否为HTML格式
    var isHTML: Bool {
        return self.contains("<") && self.contains(">")
    }
}
