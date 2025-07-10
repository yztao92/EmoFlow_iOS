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
    @Published var date: Date
    @Published var messages: [ChatMessage]
    @Published var summary: String
    @Published var emotion: EmotionType?

    var safeEmotion: EmotionType { emotion ?? .happy }

    enum CodingKeys: String, CodingKey {
        case id, date, messages, summary, emotion
    }

    init(id: UUID, date: Date, messages: [ChatMessage], summary: String, emotion: EmotionType?) {
        self.id = id
        self.date = date
        self.messages = messages
        self.summary = summary
        self.emotion = emotion
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let date = try container.decode(Date.self, forKey: .date)
        let messages = try container.decode([ChatMessage].self, forKey: .messages)
        let summary = try container.decode(String.self, forKey: .summary)
        let emotion = try container.decodeIfPresent(EmotionType.self, forKey: .emotion)
        self.init(id: id, date: date, messages: messages, summary: summary, emotion: emotion)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(messages, forKey: .messages)
        try container.encode(summary, forKey: .summary)
        try container.encode(emotion, forKey: .emotion)
    }
}
