//  ChatRecord.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.

import Foundation

struct ChatRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let messages: [ChatMessage]
    let summary: String
    let emotion: EmotionType?  // ✅ 改为 Optional

    // Optional fallback
    var safeEmotion: EmotionType {
        emotion ?? .happy
    }
}
