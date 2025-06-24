//
//  JournalService.swift
//  EmoFlow
//
//  Created by 杨振涛 on 2025/6/24.
//

import Foundation

struct JournalRequestPayload: Codable {
    let emotions: [String]
    let messages: [ChatMessageDTO]
}

struct JournalResponse: Codable {
    let journal: String
}

class JournalService {
    static let shared = JournalService()
    private init() {}

    private let url = URL(string: "http://47.238.87.240:8000/journal/generate")!

    func generateJournal(emotions: [EmotionType], messages: [ChatMessageDTO]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = JournalRequestPayload(
            emotions: emotions.map { $0.rawValue },
            messages: messages
        )

        request.httpBody = try JSONEncoder().encode(payload)
        let (data, _) = try await URLSession.shared.data(for: request)

        print("📘 返回日记原始数据:", String(data: data, encoding: .utf8) ?? "无数据")

        let decoded = try JSONDecoder().decode(JournalResponse.self, from: data)
        return decoded.journal
    }
}
