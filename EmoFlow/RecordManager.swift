// RecordManager.swift
import Foundation

struct RecordManager {
    static let storageKey = "chat_records"

    static func saveAll(_ records: [ChatRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func loadAll() -> [ChatRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let records = try? JSONDecoder().decode([ChatRecord].self, from: data)
        else {
            return []
        }
        return records
    }

    /// 新增：删除指定记录
    static func delete(_ record: ChatRecord) {
        var all = loadAll()
        all.removeAll { $0.id == record.id }
        saveAll(all)
    }

    /// 其他已有方法…
}
