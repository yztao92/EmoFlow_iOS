// ChatRecord.swift
import Foundation

struct ChatRecord: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let date: Date
    let messages: [ChatMessage]
    let summary: String
    let emotion: EmotionType?

    var safeEmotion: EmotionType { emotion ?? .happy }

    // 只用 id 做 Equatable
    static func ==(lhs: ChatRecord, rhs: ChatRecord) -> Bool {
        lhs.id == rhs.id
    }

    // 只用 id 做 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
