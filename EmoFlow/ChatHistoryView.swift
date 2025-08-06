import SwiftUI

/// 聊天历史记录视图，展示心情日记列表
struct ChatHistoryView: View {
    @State private var records: [ChatRecord] = []
    @State private var selectedTab: Int = 0 // 0: 列表, 1: 洞察
    @Binding var navigationPath: NavigationPath
    
    // 按日期排序的记录
    private var sortedRecords: [ChatRecord] {
        records.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 分段控制器
            HStack(spacing: 0) {
                Button(action: { selectedTab = 0 }) {
                    Text("列表")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 0 ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedTab == 0 ? Color(.systemGray6) : Color.clear)
                        .cornerRadius(8)
                }
                
                Button(action: { selectedTab = 1 }) {
                    Text("洞察")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 1 ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedTab == 1 ? Color(.systemGray6) : Color.clear)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            // 内容区域
            if selectedTab == 0 {
                diaryListView
            } else {
                insightsView
            }
        }
        .background(Color(.systemGray6))
        .navigationTitle("日记")
        .navigationBarBackButtonHidden(true)  // 隐藏系统默认的返回按钮
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    // 统一使用 removeLast() 返回
                    if !navigationPath.isEmpty {
                        navigationPath.removeLast()
                    }
                }
            }
        }
        .onAppear { 
            print("🔍 ChatHistoryView - onAppear")
            
            // 正常加载本地数据
            loadRecords()
            print("   records count: \(records.count)")
        }
    }
    
    // 日记列表视图
    private var diaryListView: some View {
        List {
            ForEach(sortedRecords) { record in
                JournalEntryCard(
                    record: record,
                    onTap: {
                        // 确保使用最新的数据
                        if let backendId = record.backendId {
                            // 尝试从后端获取最新的日记详情
                            Task {
                                do {
                                    let detailRecord = try await JournalDetailService.shared.fetchJournalDetail(journalId: backendId)
                                    await MainActor.run {
                                        // 直接调用回调，让 MainView 处理导航
                                        navigationPath.append(AppRoute.journalDetail(id: backendId))
                                    }
                                } catch {
                                    print("❌ 获取日记详情失败: \(error)")
                                    // 如果获取失败，使用本地数据
                                    navigationPath.append(AppRoute.journalDetail(id: backendId))
                                }
                            }
                        } else {
                            // 没有 backendId，无法导航
                            print("⚠️ 无法导航：缺少 backendId")
                        }
                    },
                    onEdit: {
                        // 编辑逻辑：调用 onJournalSelected 回调，让 MainView 处理导航
                        if let backendId = record.backendId {
                            // 这里需要一个新的路由来处理编辑模式
                            // 暂时先导航到详情页面
                            navigationPath.append(AppRoute.journalDetail(id: backendId))
                        }
                    },
                    onDelete: {
                        delete(record)
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                .padding(.horizontal, 16)
                .padding(.vertical, 8)
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
            print("🔍 ChatHistoryView - 开始刷新日记列表")
            let newJournals = try await JournalListService.shared.fetchJournals(limit: 100, offset: 0)
            print("   ✅ 从后端获取到 \(newJournals.count) 条日记")
            print("   日记的 backendId: \(newJournals.map { $0.backendId ?? -1 })")
            
            RecordManager.saveAll(newJournals)
            print("   ✅ 已保存到本地存储")
            
            await MainActor.run {
                records = newJournals.sorted { $0.date > $1.date }
                print("   ✅ 已更新 records，当前数量: \(records.count)")
                print("   records 的 backendId: \(records.map { $0.backendId ?? -1 })")
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
}

// 日记卡片组件
struct JournalEntryCard: View {
    let record: ChatRecord
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showActionSheet = false
    
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
                    // 1. 情绪icon + 日期 + more按钮
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
                        
                        // More按钮
                        Button(action: {
                            showActionSheet = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(90))
                        }
                        .buttonStyle(PlainButtonStyle())
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
                    Text(record.plainTextContent)
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
        .confirmationDialog("选择操作", isPresented: $showActionSheet, titleVisibility: .hidden) {
            Button("编辑") {
                onEdit()
            }
            
            Button("删除", role: .destructive) {
                onDelete()
            }
            
            Button("取消", role: .cancel) { }
        }
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
