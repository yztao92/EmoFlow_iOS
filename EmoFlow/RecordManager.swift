//
//  RecordManager.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//

import Foundation

struct RecordManager {
    static let storageKey = "chat_records"

    static func saveAll(_ records: [ChatRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func save(messages: [ChatMessage], emotions: [EmotionType]) {
        guard let first = messages.first else { return }

        let record = ChatRecord(
            id: UUID(),
            date: Date(),
            messages: messages,
            summary: first.content,
            emotion: emotions.first ?? .happy  // ✅ 新增字段
        )

        var all = loadAll()
        all.append(record)
        saveAll(all)
    }

    static func loadAll() -> [ChatRecord] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let records = try? JSONDecoder().decode([ChatRecord].self, from: data) {
            return records
        }
        return []
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
