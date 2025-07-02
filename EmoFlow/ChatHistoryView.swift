import SwiftUI

struct ChatHistoryView: View {
    @Binding var selectedRecord: ChatRecord?
    @State private var records: [ChatRecord] = RecordManager.loadAll()
    @State private var selectedEmotion: EmotionType? = nil
    
    // 筛选栏数据
    private let filterTabs: [(icon: String?, label: String?, emotion: EmotionType?)] = [
        (nil, "所有", nil),
        ("EmojiHappy", "开心", .happy),
        ("EmojiTired", "疲惫", .tired),
        ("EmojiSad", "悲伤", .sad),
        ("EmojiAngry", "愤怒", .angry)
    ]
    
    // 统计所有记录中实际存在的情绪类型
    private var allEmotions: [EmotionType] {
        Set(records.compactMap { $0.emotion }).sorted { $0.rawValue < $1.rawValue }
    }
    
    // 构建动态filterTabs
    private var dynamicFilterTabs: [(icon: String?, label: String, emotion: EmotionType?)] {
        var tabs: [(icon: String?, label: String, emotion: EmotionType?)] = [ (nil, "所有", nil) ]
        for emo in allEmotions {
            tabs.append((emo.iconName, emo.displayName, emo))
        }
        return tabs
    }
    
    // 分组数据
    private var groupedRecords: [(date: String, items: [ChatRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let groups = Dictionary(grouping: filteredRecords) { record in
            formatter.string(from: record.date)
        }
        return groups.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }
    
    private var filteredRecords: [ChatRecord] {
        if let emo = selectedEmotion {
            return records.filter { $0.emotion == emo }
        } else {
            return records
        }
    }
    
    // 判断是否显示filter
    private var shouldShowFilter: Bool {
        if selectedEmotion == nil {
            return allEmotions.count >= 2
        } else {
            return true
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部大标题
            // Text("心情日记")
            //     .font(.system(size: 28, weight: .bold))
            //     .frame(maxWidth: .infinity)
            //     .padding(.top, 24)
            //     .padding(.bottom, 8)
            // 吸顶筛选栏
            if shouldShowFilter {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dynamicFilterTabs, id: \ .label) { tab in
                            let isSelected = selectedEmotion == tab.emotion
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    selectedEmotion = tab.emotion
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if let icon = tab.icon, !icon.isEmpty {
                                        Image(icon)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                    }
                                    Text(tab.label)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.white : Color.clear)
                                .foregroundColor(isSelected ? .blue : .gray)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))
            }
            // 分组列表
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(groupedRecords, id: \ .date) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(group.date)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.leading, 18)
                                .padding(.vertical, 8)
                            HistoryDayCardView(records: group.items, selectedRecord: $selectedRecord, onDelete: { record in
                                delete(record)
                            })
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            records = RecordManager.loadAll()
        }
    }
    
    private func delete(_ record: ChatRecord) {
        RecordManager.delete(record)
        records.removeAll { $0.id == record.id }
    }
}

struct HistoryDayCardView: View {
    let records: [ChatRecord]
    @Binding var selectedRecord: ChatRecord?
    var onDelete: (ChatRecord) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let sortedRecords = records.sorted(by: { $0.date > $1.date })
            ForEach(Array(sortedRecords.enumerated()), id: \ .element.id) { idx, record in
                Button(action: {
                    selectedRecord = record
                }) {
                    HStack {
                        Image((record.emotion?.iconName) ?? "EmojiHappy")
                            .resizable()
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.summary.isEmpty ? "Recordings" : record.summary)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text(timeString(record.date))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                .buttonStyle(PlainButtonStyle())
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        onDelete(record)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                if idx < sortedRecords.count - 1 {
                    Divider().padding(.leading, 36)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
