import SwiftUI

/// 聊天历史记录视图，展示心情日记列表
struct ChatHistoryView: View {
    @Binding var selectedRecord: ChatRecord?
    @State private var records: [ChatRecord] = []
    @State private var selectedTab: Int = 0 // 0: 列表, 1: 洞察
    @State private var showEditView = false // 控制编辑页面显示
    @State private var editingRecord: ChatRecord? = nil // 正在编辑的记录
    var navigateToJournalId: Int? = nil // 接收导航目标
    var onNavigationComplete: (() -> Void)? = nil // 导航完成后的回调
    
    // 按日期排序的记录
    private var sortedRecords: [ChatRecord] {
        records.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            Text("日记")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 8)
            
            // 分段控制器
            HStack(spacing: 0) {
                Button(action: { selectedTab = 0 }) {
                    Text("列表")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 0 ? .blue : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedTab == 0 ? Color(.systemBackground) : Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                Button(action: { selectedTab = 1 }) {
                    Text("洞察")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 1 ? .blue : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedTab == 1 ? Color(.systemBackground) : Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // 内容区域
            if selectedTab == 0 {
                diaryListView
            } else {
                insightsView
            }
        }
        .background(Color(.systemGray6))
        .navigationBarHidden(true)
        .onAppear { 
            loadRecords()
            // 如果有导航目标，查找对应的记录并导航
            if let journalId = navigateToJournalId {
                if let record = findRecordByJournalId(journalId) {
                    selectedRecord = record
                    // 导航完成后清除状态
                    onNavigationComplete?()
                }
            }
        }
        .navigationDestination(isPresented: $showEditView) {
            if let record = editingRecord {
                JournalEditView(
                    initialEmotion: record.emotion ?? .peaceful,
                    isEditMode: true,
                    editJournalId: record.backendId,
                    onJournalUpdated: { journalId in
                        // 编辑完成后刷新列表
                        Task {
                            await refreshJournals()
                        }
                    },
                    initialTitle: record.title ?? "",
                    initialContent: record.summary
                )
            }
        }
    }
    
    // 日记列表视图
    private var diaryListView: some View {
        List {
            ForEach(sortedRecords) { record in
                JournalEntryCard(record: record) {
                    selectedRecord = record
                    // 手动点击时也清除导航状态
                    onNavigationComplete?()
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // 删除按钮
                    Button(role: .destructive) {
                        delete(record)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    
                    // 编辑按钮
                    Button {
                        editJournal(record)
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(.systemGray6))
        .refreshable {
            await refreshJournals()
        }
    }
    
    // 洞察视图（暂时显示占位内容）
    private var insightsView: some View {
        VStack {
            Spacer()
            Text("洞察功能开发中...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private func loadRecords() {
        records = RecordManager.loadAll().sorted { $0.date > $1.date }
    }
    
    private func findRecordByJournalId(_ journalId: Int) -> ChatRecord? {
        return records.first { $0.backendId == journalId }
    }
    
    private func refreshJournals() async {
        do {
            let newJournals = try await JournalListService.shared.fetchJournals(limit: 100, offset: 0)
            RecordManager.saveAll(newJournals)
            await MainActor.run {
                records = newJournals.sorted { $0.date > $1.date }
            }
            print("✅ 日记列表刷新成功")
        } catch {
            print("❌ 日记列表刷新失败: \(error)")
        }
    }
    
    private func delete(_ record: ChatRecord) {
        // 先删除本地记录
        withAnimation {
            RecordManager.delete(record)
            records.removeAll { $0.id == record.id }
        }
        
        // 调用后端删除API
        if let backendId = record.backendId {
            Task {
                do {
                    let success = try await JournalDeleteService.shared.deleteJournal(journalId: backendId)
                    if success {
                        print("✅ 后端日记删除成功")
                        // 刷新日记列表
                        await refreshJournals()
                    }
                } catch {
                    print("❌ 后端日记删除失败: \(error)")
                }
            }
        } else {
            print("⚠️ 无法删除后端日记：缺少backendId")
        }
    }
    
    private func editJournal(_ record: ChatRecord) {
        editingRecord = record
        showEditView = true
    }
}

// 日记卡片组件
struct JournalEntryCard: View {
    let record: ChatRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 左侧彩色时间线
                Rectangle()
                    .fill(record.emotion?.color ?? .gray)
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)
                
                // 主要内容区域
                VStack(alignment: .leading, spacing: 0) {
                    // 1. 情绪icon + 日期
                    HStack(spacing: 12) {
                        // 情绪图标
                        Image(record.emotion?.iconName ?? "Happy")
                            .resizable()
                            .frame(width: 48, height: 48)
                        
                        // 日期
                        Text(formatDate(record.date))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 间隔 8px
                    Spacer().frame(height: 8)
                    
                    // 2. 时间
                    HStack {
                        Text(formatTime(record.date))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    // 间隔 8px
                    Spacer().frame(height: 8)
                    
                    // 3. 日记标题
                    Text(record.title ?? "无标题")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                    
                    // 间隔 20px
                    Spacer().frame(height: 20)
                    
                    // 4. 日记正文
                    Text(record.summary.isEmpty ? "无内容" : record.summary)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func getEmotionText(_ emotion: EmotionType?) -> String {
        guard let emotion = emotion else { return "未知情绪" }
        
        switch emotion {
        case .peaceful:
            return "无风无浪的一天"
        case .happy:
            return "今天蛮开心的"
        case .unhappy:
            return "今天我是不大高兴了"
        case .sad:
            return "唉，哭了"
        case .angry:
            return "哼，气死我得了"
        case .happiness:
            return "满满的幸福"
        }
    }
}
