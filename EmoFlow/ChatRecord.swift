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

    var safeEmotion: EmotionType { emotion ?? .happy }
    
    /// 获取纯文本内容（去除HTML标签）
    var plainTextContent: String {
        // 现在后端已经修复，可以直接使用content_plain字段
        // 但为了兼容性，我们仍然保留自己的解析逻辑作为备用
        
        // 首先尝试使用后端的content_plain字段（如果可用）
        // 但由于后端可能有问题，我们主要依赖自己的解析逻辑
        
        let htmlString = summary.htmlToString()
        
        // 移除CSS样式代码和其他HTML残留
        let cleanText = htmlString
            .replacingOccurrences(of: "p.p1 {margin: 0.0px 0.0px 12.0px 0.0px; text-align: center; font: 12.0px 'Times New Roman'; color: #000000; -webkit-text-stroke: #000000; min-height: 13.8px}", with: "")
            .replacingOccurrences(of: "p.p2 {margin: 0.0px 0.0px 12.0px 0.0px; text-align: center; font: 12.0px 'Times New Roman'; color: #000000; -webkit-text-stroke: #000000}", with: "")
            .replacingOccurrences(of: "span.s1 {font-family: 'Times New Roman'; font-weight: normal; font-style: normal; font-size: 12.00px; font-kerning: none}", with: "")
            // 移除我们生成的CSS样式
            .replacingOccurrences(of: "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; line-height: 1.5; }", with: "")
            .replacingOccurrences(of: "p { margin: 0; padding: 0; text-align: center; }", with: "")
            .replacingOccurrences(of: "strong { font-weight: bold; }", with: "")
            .replacingOccurrences(of: "em { font-style: italic; }", with: "")
            .replacingOccurrences(of: "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; line-height: 1.5; } p { margin: 0; padding: 0; text-align: center; } strong { font-weight: bold; } em { font-style: italic; }", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果清理后为空，返回原始文本
        if cleanText.isEmpty {
            return "无内容"
        }
        
        // 进一步清理可能的HTML标签残留
        let finalText = cleanText
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return finalText.isEmpty ? "无内容" : finalText
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
        case id, backendId, date, messages, summary, emotion, title, isEdited, originalTimeString
    }

    init(id: UUID, backendId: Int? = nil, date: Date, messages: [ChatMessage], summary: String, emotion: EmotionType?, title: String? = nil, isEdited: Bool = false, originalTimeString: String? = nil) {
        self.id = id
        self.backendId = backendId
        self.date = date
        self.messages = messages
        self.summary = summary
        self.emotion = emotion
        self.title = title
        self.isEdited = isEdited
        self.originalTimeString = originalTimeString
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
        self.init(id: id, backendId: backendId, date: date, messages: messages, summary: summary, emotion: emotion, title: title, isEdited: isEdited, originalTimeString: originalTimeString)
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
