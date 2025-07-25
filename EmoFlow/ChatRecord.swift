// ChatRecord.swift
import Foundation
import SwiftUI

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

    var safeEmotion: EmotionType { emotion ?? .happy }

    enum CodingKeys: String, CodingKey {
        case id, backendId, date, messages, summary, emotion, title
    }

    init(id: UUID, backendId: Int? = nil, date: Date, messages: [ChatMessage], summary: String, emotion: EmotionType?, title: String? = nil) {
        self.id = id
        self.backendId = backendId
        self.date = date
        self.messages = messages
        self.summary = summary
        self.emotion = emotion
        self.title = title
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
        self.init(id: id, backendId: backendId, date: date, messages: messages, summary: summary, emotion: emotion, title: title)
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
    }
}
