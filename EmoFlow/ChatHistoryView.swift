import SwiftUI

/// 聊天历史记录视图，展示按日期分组的心情日记列表
/// 支持按情绪类型筛选和iOS原生左滑删除功能
struct ChatHistoryView: View {
    @Binding var selectedRecord: ChatRecord?
    @State private var records: [ChatRecord] = []
    @State private var selectedEmotion: EmotionType? = nil
    
    private let filterTabs: [(icon: String?, label: String, emotion: EmotionType?)] = [
        (nil, "所有", nil),
        ("Happy", "开心", .happy),
        ("Unhappy", "不开心", .unhappy),
        ("Sad", "悲伤", .sad),
        ("Angry", "愤怒", .angry),
        ("Peaceful", "平和", .peaceful),
        ("Happiness", "幸福", .happiness)
    ]
    
    // 动态筛选标签
    private var dynamicFilterTabs: [(icon: String?, label: String, emotion: EmotionType?)] {
        var tabs: [(icon: String?, label: String, emotion: EmotionType?)] = []
        let existingEmotions = Set(records.compactMap { $0.emotion })
        tabs.append((nil, "所有", nil))
        for tab in filterTabs.dropFirst() {
            if let emotion = tab.emotion, existingEmotions.contains(emotion) {
                tabs.append(tab)
            }
        }
        return tabs
    }
    
    // 分组数据
    private var groupedRecords: [(date: Date, items: [ChatRecord])] {
        let groups = Dictionary(grouping: filteredRecords) { record in
            Calendar.current.startOfDay(for: record.date)
        }
        return groups
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.0 > $1.0 }
    }
    
    private var filteredRecords: [ChatRecord] {
        selectedEmotion.map { emo in
            records.filter { $0.emotion == emo }
        } ?? records
    }
    
    // 将列表部分提取为单独的计算属性
    private var diaryList: some View {
        List {
            ForEach(groupedRecords, id: \.date) { group in
                Section(header:
                    DateHeaderView(date: group.date)
                        .padding(.top, 2) // 调整为8，实现更小的分组间距
                ) {
                                            ForEach(group.items) { record in
                            Button(action: {
                                selectedRecord = record
                            }) {
                                DiaryRowView(record: record)
                                    .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.visible)
                                    .listRowBackground(Color.clear)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                DeleteSwipeAction { 
                                    delete(record)
                                }
                            }
                        }
                }
                .listSectionSeparator(.hidden)
                // .sectionHeaderTopPadding(16) 已移除
            }
        }
        .headerProminence(.increased)
        .listStyle(.insetGrouped)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs section:
            if !dynamicFilterTabs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dynamicFilterTabs, id: \.label) { tab in
                            FilterTabButton(tab: tab, isSelected: selectedEmotion == tab.emotion) {
                                withAnimation(.easeInOut) {
                                    selectedEmotion = tab.emotion
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            
            // Use the list view
            diaryList
                .navigationTitle("心情日记")
                .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { loadRecords() }
    }
    
    private func loadRecords() {
        records = RecordManager.loadAll().sorted { $0.date > $1.date }
    }
    
    private func delete(_ record: ChatRecord) {
        withAnimation {
        RecordManager.delete(record)
        records.removeAll { $0.id == record.id }
    }
}
}

// DiaryRowView 增加 isFirst/isLast 参数，首尾有圆角和阴影，中间无圆角无阴影
// 同时修改DiaryRowView的内部间距为更小的值
struct DiaryRowView: View {
    let record: ChatRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // 情绪图标
                    Image((record.emotion?.iconName) ?? "Happy")
                        .resizable()
                .frame(width: 32, height: 32)
                
            // 内容区域
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title ?? (record.summary.isEmpty ? "Recordings" : record.summary))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                
                Text(record.date, style: .time)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                }
            .padding(.vertical, 8)
            
                        Spacer()
                    }
    }
}

// 自定义只给首尾加圆角的 Shape
struct RoundedCornerShape: Shape {
    let isFirst: Bool
    let isLast: Bool
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var corners: UIRectCorner = []
        if isFirst { corners.formUnion([.topLeft, .topRight]) }
        if isLast { corners.formUnion([.bottomLeft, .bottomRight]) }
        if corners.isEmpty { corners = [] }
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 筛选标签按钮
struct FilterTabButton: View {
    let tab: (icon: String?, label: String, emotion: EmotionType?)
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = tab.icon {
                    Image(icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                Text(tab.label)
                    .font(.system(size: 14, weight: .medium))
        }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .blue : .gray)
            .cornerRadius(16)
        }
    }
}

// 日期头部视图
struct DateHeaderView: View {
    let date: Date
    
    var body: some View {
        Text(date, style: .date)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }
}

// 删除滑动操作
struct DeleteSwipeAction: View {
    let action: () -> Void
    
    var body: some View {
        Button(role: .destructive, action: action) {
            Label("删除", systemImage: "trash")
        }
    }
}
