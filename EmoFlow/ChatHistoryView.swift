import SwiftUI
import Combine

// 弹窗管理器
class ActionSheetManager: ObservableObject {
    @Published var showActionSheet = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    func show(onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.showActionSheet = true
    }
}

/// 聊天历史记录视图，展示心情日记列表
struct ChatHistoryView: View {
    @State private var records: [ChatRecord] = []
    @State private var selectedTab: Int = 0 // 0: 列表, 1: 洞察
    @State private var isLoading = false // 添加加载状态
    @Binding var navigationPath: NavigationPath
    @StateObject private var actionSheetManager = ActionSheetManager()
    let refreshTrigger: UUID
    
    // 月份选择器相关状态
    @State private var selectedDate = Date()
    @State private var showYearPicker = false
    
    // 日记选择相关状态
    @State private var showJournalSelector = false
    @State private var selectedDay = 0
    @State private var selectedDayRecords: [ChatRecord] = []
    
    // 日记预览弹窗相关状态
    @State private var showJournalPreview = false
    @State private var previewRecord: ChatRecord?
    @State private var pendingPreviewRecord: ChatRecord? // 新增：待显示的记录
    @State private var currentPreviewRecord: ChatRecord? // 新增：当前显示的记录
    @State private var hasImagesInPreview = false // 新增：预览中是否有图片

    @State private var isEditMode = false // 新增：是否为编辑模式
    
    // 情绪日记列表弹窗相关状态
    @State private var showEmotionJournalList = false
    @State private var selectedEmotion: EmotionType?
    
    // 按日期排序的记录
    private var sortedRecords: [ChatRecord] {
        records.sorted { $0.date > $1.date }
    }
    
    // 根据选择的月份筛选记录
    private var filteredRecords: [ChatRecord] {
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)
        
        return sortedRecords.filter { record in
            let recordMonth = calendar.component(.month, from: record.date)
            let recordYear = calendar.component(.year, from: record.date)
            return recordMonth == selectedMonth && recordYear == selectedYear
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 分段控制器
            HStack(spacing: 0) {
                Button(action: { selectedTab = 0 }) {
                    Text("日记")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 0 ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedTab == 0 ? ColorManager.sysbackground : Color.clear)
                        .cornerRadius(8)
                }
                
                Button(action: { selectedTab = 1 }) {
                    Text("情绪")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == 1 ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedTab == 1 ? ColorManager.sysbackground : Color.clear)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(ColorManager.cardbackground)
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
        .background(ColorManager.sysbackground)
        .navigationBarBackButtonHidden(true)  // 隐藏系统默认的返回按钮
        .navigationBarItems(
            leading: Button(action: {
                // 统一使用 removeLast() 返回
                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.primary)
            }
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthPickerView(
                    selectedDate: $selectedDate,
                    showYearPicker: $showYearPicker
                )
            }
        }
        .onAppear { 
            print("🔍 ChatHistoryView - onAppear")
            
            // 第一次进入时强制刷新数据，确保数据是最新的
            forceRefreshData()
            print("   records count: \(records.count)")
        }
        .onChange(of: refreshTrigger) { _ in
            print("🔍 ChatHistoryView - refreshTrigger 变化，从本地加载数据")
            // 直接从本地加载数据，因为数据已经在跳转前刷新好了
            records = RecordManager.loadAll().sorted { $0.date > $1.date }
            print("✅ ChatHistoryView - 已从本地加载 \(records.count) 条日记")
        }
        .onReceive(NotificationCenter.default.publisher(for: .journalDeleted)) { _ in
            print("🔍 ChatHistoryView - 收到日记删除通知，重新加载数据")
            // 重新加载数据以更新情绪占比和日历
            forceRefreshData()
        }
        .confirmationDialog(
            "选择操作",
            isPresented: $actionSheetManager.showActionSheet,
            titleVisibility: .visible
        ) {
            Button("编辑") {
                actionSheetManager.onEdit?()
            }
            Button("删除", role: .destructive) {
                actionSheetManager.onDelete?()
            }
            Button("取消", role: .cancel) { }
        }
        .sheet(isPresented: $showYearPicker) {
            YearPickerView(selectedDate: $selectedDate, isPresented: $showYearPicker)
        }
        .sheet(isPresented: $showJournalSelector) {
            JournalSelectorSheet(
                day: $selectedDay,
                records: $selectedDayRecords,
                isPresented: $showJournalSelector,
                navigationPath: $navigationPath
            )
        }
        .sheet(item: $currentPreviewRecord) { record in
            FloatingModalView(
                currentEmotion: EmotionData.emotions.first { $0.emotionType == record.emotion } ?? EmotionData.emotions[3],
                mode: isEditMode ? .edit : .preview,
                previewRecord: record,
                onDelete: {
                    print("🗑️ ChatHistoryView - onDelete 回调被调用")
                    print("   要删除的 record.id: \(record.id.uuidString)")
                    
                    // 从当前记录列表中移除
                    records.removeAll { $0.id == record.id }
                    print("   ✅ 已从当前记录列表中移除")
                    
                    // 关闭预览弹窗
                    currentPreviewRecord = nil
                    print("   ✅ 已关闭预览弹窗")
                },
                onEdit: {
                    print("🔄 ChatHistoryView onEdit 回调被调用 - 开始编辑")
                    print("   record.id: \(record.id)")
                    print("   当前内容: '\(record.plainTextContent)'")
                    
                    // 从预览模式切换到编辑模式
                    print("   📝 从预览模式切换到编辑模式")
                    showEditJournal(record: record)
                },
                onEditComplete: {
                    print("🔄 ChatHistoryView onEditComplete 回调被调用 - 编辑完成")
                    print("   record.id: \(record.id)")
                    
                    // 编辑完成，关闭弹窗并重新加载数据
                    print("   📝 编辑完成，关闭弹窗")
                    
                    // 从本地缓存重新加载最新数据
                    let latestRecords = RecordManager.loadAll().sorted { $0.date > $1.date }
                    print("   🔄 从本地缓存加载了 \(latestRecords.count) 条记录")
                    records = latestRecords
                    
                    // 关闭弹窗
                    currentPreviewRecord = nil
                    isEditMode = false
                    print("   ✅ 已关闭弹窗")
                },
                isPresented: $showJournalPreview,
                navigationPath: $navigationPath
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .sheet(item: $selectedEmotion) { emotion in
            EmotionJournalListSheet(
                emotion: emotion,
                selectedDate: selectedDate,
                isPresented: $showEmotionJournalList,
                navigationPath: $navigationPath
            )
        }
    }
    
    // 日记列表视图
    private var diaryListView: some View {
        Group {
            if isLoading {
                // 加载状态
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("正在加载日记列表...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                }
            } else if filteredRecords.isEmpty {
                // 空状态
                EmptyStateView()
            } else {
                // 日记列表 - 使用 ScrollView 替代 List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredRecords) { record in
                            JournalEntryCard(
                                record: record,
                                onTap: {
                                    print("🔘 日记卡片被点击")
                                    print("   isLoading: \(isLoading)")
                                    print("   record.id: \(record.id)")
                                    print("   record.plainTextContent: '\(record.plainTextContent)'")
                                    
                                    // 只有在非加载状态下才允许点击
                                    guard !isLoading else {
                                        print("⚠️ 数据加载中，暂时禁用点击")
                                        return
                                    }
                                    
                                    // 显示日记预览弹窗
                                    showJournalPreview(record: record)
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 0)
                        }
                    }
                    .padding(.top, 4) // 改为4px，与情绪模块保持一致
                    .padding(.bottom, 8)
                }
                .background(ColorManager.sysbackground)
                .refreshable {
                    await refreshJournals()
                }
            }
        }
    }
    
    // 情绪视图
    @ViewBuilder
    private var insightsView: some View {
        if filteredRecords.isEmpty {
            // 空状态视图
            EmptyStateView()
        } else {
            // 有数据时显示日历和统计
            EmotionCalendarView(
                records: filteredRecords, 
                selectedDate: selectedDate, 
                showJournalSelector: $showJournalSelector,
                selectedDay: $selectedDay,
                selectedDayRecords: $selectedDayRecords,
                onJournalPreview: showJournalPreview,
                onEmotionTap: { emotion in
                    handleEmotionTap(emotion: emotion)
                },
                navigationPath: $navigationPath
            )
        }
    }
    
    private func loadRecords() {
        // 异步加载数据，避免阻塞UI
        Task {
            await loadRecordsAsync()
        }
    }
    
    // 新增：强制刷新数据的方法
    private func forceRefreshData() {
        Task {
            await MainActor.run {
                isLoading = true
                print("🔄 强制刷新数据...")
            }
            
            // 先尝试从后端获取最新数据
            do {
                let newJournals = try await JournalListService.shared.fetchJournals(limit: 100, offset: 0)
                print("   ✅ 从后端获取到 \(newJournals.count) 条日记")
                
                // 保存到本地缓存
                RecordManager.saveAll(newJournals)
                print("   ✅ 已更新本地缓存")
                
                // 更新UI
                await MainActor.run {
                    withAnimation {
                        records = newJournals.sorted { $0.date > $1.date }
                    }
                    isLoading = false
                    print("   ✅ 强制刷新完成，records count: \(records.count)")
                }
            } catch {
                print("❌ 强制刷新失败: \(error)")
                // 如果刷新失败，仍然加载本地数据
                await loadRecordsAsync()
            }
        }
    }
    
    private func loadRecordsAsync() async {
        // 设置加载状态
        await MainActor.run {
            isLoading = true
            print("🔍 ChatHistoryView - 开始异步加载数据")
        }
        
        // 在后台线程加载数据
        let loadedRecords = await Task.detached {
            let records = RecordManager.loadAll().sorted { $0.date > $1.date }
            print("🔍 后台线程加载完成，获取到 \(records.count) 条记录")
            
            // 调试：检查前几条记录的内容
            for (index, record) in records.prefix(3).enumerated() {
                print("   记录 \(index + 1): ID=\(record.id), summary='\(record.summary)', summary长度=\(record.summary.count)")
            }
            
            return records
        }.value
        
        // 在主线程更新UI
        await MainActor.run {
            records = loadedRecords
            isLoading = false
            print("🔍 ChatHistoryView - 异步加载完成，records count: \(records.count)")
            print("🔍 数据加载状态：isLoading = \(isLoading)")
        }
    }
    
    private func findRecordByJournalId(_ journalId: Int) -> ChatRecord? {
        return records.first { $0.backendId == journalId }
    }
    
    private func refreshJournals() async {
        do {
            print("🔍 ChatHistoryView - 开始刷新日记列表")
            let newJournals = try await JournalListService.shared.fetchJournals(limit: 100, offset: 0)
            print("   ✅ 从后端获取到 \(newJournals.count) 条日记")
            
            RecordManager.saveAll(newJournals)
            print("   ✅ 已保存到本地存储")
            
            await MainActor.run {
                withAnimation {
                    records = newJournals.sorted { $0.date > $1.date }
                }
                print("   ✅ 已更新 records，当前数量: \(records.count)")
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
    
    // 显示日记预览弹窗
    private func showJournalPreview(record: ChatRecord) {
        // 首先检查是否还在加载中
        guard !isLoading else {
            print("⚠️ 数据仍在加载中，暂时禁用预览")
            return
        }
        
        // 基本的数据验证（移除过于严格的检查）
        print("🔍 准备显示日记预览")
        print("   record.plainTextContent: '\(record.plainTextContent)'")
        print("   record.summary: '\(record.summary)'")
        print("   record.summary 长度: \(record.summary.count)")
        print("   record.id: \(record.id)")
        print("   record.backendId: \(record.backendId ?? -1)")
        print("   record.messages count: \(record.messages.count)")
        if !record.messages.isEmpty {
            print("   第一条消息: '\(record.messages.first?.content ?? "nil")'")
        }
        
        // 验证记录是否在当前的records数组中（放宽验证，添加详细日志）
        let recordExists = records.contains(where: { $0.id == record.id })
        print("🔍 记录验证结果: \(recordExists)")
        print("   record.id: \(record.id)")
        print("   current records count: \(records.count)")
        
        if !recordExists {
            print("⚠️ 记录不在当前数据集中，但仍继续显示预览")
            // 不再直接返回，允许显示预览
        }
        
        print("✅ 日记数据完整，显示预览")
        print("   record.plainTextContent: '\(record.plainTextContent)'")
        print("   record.id: \(record.id)")
        print("   isLoading: \(isLoading)")
        print("   records count: \(records.count)")
        
        // 直接设置当前显示的记录
        currentPreviewRecord = record
        isEditMode = false // 默认为预览模式
        print("🔍 currentPreviewRecord 已设置为: \(record.id)")
        print("🔍 设置后的 currentPreviewRecord summary: '\(record.summary)'")
        print("🔍 设置后的 currentPreviewRecord plainTextContent: '\(record.plainTextContent)'")
        
        // 直接设置弹窗状态，不使用延迟
        print("🔍 准备显示弹窗，currentPreviewRecord: \(currentPreviewRecord?.id.uuidString ?? "nil")")
        print("🔍 currentPreviewRecord 内容: '\(currentPreviewRecord?.plainTextContent ?? "nil")'")
        print("🔍 currentPreviewRecord summary: '\(currentPreviewRecord?.summary ?? "nil")'")
        // 使用 sheet(item:) 时，只需要设置 currentPreviewRecord，不需要 showJournalPreview
        print("🔍 弹窗将通过 currentPreviewRecord 自动显示")
    }
    
    // 显示编辑模式的弹窗
    private func showEditJournal(record: ChatRecord) {
        // 设置当前显示的记录和编辑模式
        currentPreviewRecord = record
        isEditMode = true
        print("🔍 切换到编辑模式，record: \(record.id)")
        
        // 直接设置弹窗状态，不使用延迟
        print("🔍 准备显示编辑弹窗，currentPreviewRecord: \(currentPreviewRecord?.id.uuidString ?? "nil")")
        // 使用 sheet(item:) 时，只需要设置 currentPreviewRecord，不需要 showJournalPreview
        print("🔍 编辑弹窗将通过 currentPreviewRecord 自动显示")
    }
    
    // 显示情绪日记列表
    private func handleEmotionTap(emotion: EmotionType) {
        selectedEmotion = emotion
        print("🔍 显示情绪日记列表，情绪: \(emotion.displayName)")
    }
}

// 日记卡片组件
struct JournalEntryCard: View {
    let record: ChatRecord
    let onTap: () -> Void
    
    // 根据情绪获取对应的 primary 颜色
    private var emotionPrimaryColor: Color {
        guard let emotion = record.emotion else { 
            return .gray 
        }
        
        switch emotion {
        case .happy:
            return ColorManager.Happy.primary
        case .sad:
            return ColorManager.Sad.primary
        case .angry:
            return ColorManager.Angry.primary
        case .peaceful:
            return ColorManager.Peaceful.primary
        case .happiness:
            return ColorManager.Happiness.primary
        case .unhappy:
            return ColorManager.Unhappy.primary
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧彩色时间线
            Rectangle()
                .fill(emotionPrimaryColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity)
            
            // 主要内容区域
            VStack(alignment: .leading, spacing: 0) {
                // 1. 情绪icon + 日期和时间
                HStack(spacing: 12) {
                    // 情绪图标
                    Image(record.emotion?.iconName ?? "Happy")
                        .resizable()
                        .frame(width: 36, height: 36)
                    
                    // 日期和时间
                    HStack(spacing: 8) {
                        Text(formatDate(record.date))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(formatTime(record.date))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // 图片图标（如果有图片）
                    if let imageUrls = record.image_urls, !imageUrls.isEmpty {
                        Image(systemName: "photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(emotionPrimaryColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // 间隔 8px
                Spacer().frame(height: 8)
                
                // 2. 日记标题 - 已隐藏
                // Text(record.title ?? "无标题")
                //     .font(.system(size: 20, weight: .bold))
                //     .foregroundColor(.primary)
                //     .padding(.horizontal, 16)
                
                // 间隔 4px
                Spacer().frame(height: 4)
                
                // 3. 日记正文 - 只有内容不为空时才显示
                if !record.plainTextContent.isEmpty {
                    Text(record.plainTextContent)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                } else {
                    // 内容为空时，添加底部间距，与顶部保持一致
                    Spacer().frame(height: 16)
                }
            }
        }
        .background(ColorManager.cardbackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            print("🔘 卡片被点击")
            onTap()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    

}

// 月份选择器组件
struct MonthPickerView: View {
    @Binding var selectedDate: Date
    @Binding var showYearPicker: Bool
    
    // 检查是否已经是最新月份
    private var isLatestMonth: Bool {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)
        
        return selectedYear == currentYear && selectedMonth == currentMonth
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 左箭头 - 上个月
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                    .background(ColorManager.cardbackground)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 月份显示 - 不再可点击
            Text(formatMonthYear(selectedDate))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            
            // 右箭头 - 下个月
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                    .background(ColorManager.cardbackground)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLatestMonth)
            .opacity(isLatestMonth ? 0.5 : 1.0)
        }
    }
    
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
}

// 年份选择器组件
struct YearPickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        
        let calendar = Calendar.current
        self._selectedYear = State(initialValue: calendar.component(.year, from: selectedDate.wrappedValue))
        self._selectedMonth = State(initialValue: calendar.component(.month, from: selectedDate.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 标题
                Text("选择日期")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                
                // 年份和月份选择器
                HStack(spacing: 40) {
                    // 年份选择器
                    VStack(spacing: 8) {
                        Text("年份")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Picker("年份", selection: $selectedYear) {
                            ForEach(2020...2030, id: \.self) { year in
                                Text("\(year)").tag(year)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 120, height: 120)
                    }
                    
                    // 月份选择器
                    VStack(spacing: 8) {
                        Text("月份")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Picker("月份", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)月").tag(month)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 120, height: 120)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 确定按钮
                Button(action: {
                    // 更新选中的日期
                    if let newDate = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth)) {
                        selectedDate = newDate
                    }
                    isPresented = false
                }) {
                    Text("确定")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// 情绪日历视图组件
struct EmotionCalendarView: View {
    let records: [ChatRecord]
    let selectedDate: Date // 添加selectedDate参数
    @Binding var showJournalSelector: Bool
    @Binding var selectedDay: Int
    @Binding var selectedDayRecords: [ChatRecord]
    let onJournalPreview: (ChatRecord) -> Void // 添加预览回调
    let onEmotionTap: (EmotionType) -> Void // 添加情绪点击回调
    @Binding var navigationPath: NavigationPath // 添加导航路径绑定
    @State private var hasImagesInPreview = false // 新增：预览中是否有图片
    
    // 获取传入数据对应月份的数据
    private var currentMonthData: [Int: ChatRecord] {
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)
        
        var monthData: [Int: ChatRecord] = [:]
        
        for record in records {
            let recordMonth = calendar.component(.month, from: record.date)
            let recordYear = calendar.component(.year, from: record.date)
            let recordDay = calendar.component(.day, from: record.date)
            
            // 只处理对应月份的数据
            if recordMonth == selectedMonth && recordYear == selectedYear {
                // 如果同一天有多个情绪，取最新的（按日期排序，records已经按日期倒序）
                if monthData[recordDay] == nil {
                    monthData[recordDay] = record
                }
            }
        }
        
        return monthData
    }
    
    // 获取指定日期的所有日记记录
    private func getDayRecords(for day: Int) -> [ChatRecord] {
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)
        
        return records.filter { record in
            let recordMonth = calendar.component(.month, from: record.date)
            let recordYear = calendar.component(.year, from: record.date)
            let recordDay = calendar.component(.day, from: record.date)
            return recordMonth == selectedMonth && recordYear == selectedYear && recordDay == day
        }
    }
    
    // 获取对应月份的第一天是星期几
    private var firstDayOfMonth: Int {
        let calendar = Calendar.current
        
        // 创建对应月份的第一天
        let firstDayOfMonth = calendar.date(from: DateComponents(year: calendar.component(.year, from: selectedDate), month: calendar.component(.month, from: selectedDate), day: 1)) ?? selectedDate
        return calendar.component(.weekday, from: firstDayOfMonth) - 1 // 0 = 周日, 1 = 周一, ...
    }
    
    // 获取对应月份的天数
    private var daysInMonth: Int {
        let calendar = Calendar.current
        
        // 创建对应月份的第一天
        let firstDayOfMonth = calendar.date(from: DateComponents(year: calendar.component(.year, from: selectedDate), month: calendar.component(.month, from: selectedDate), day: 1)) ?? selectedDate
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) ?? 1..<32
        return range.count
    }
    
    // 获取今天的日期
    private var today: Int {
        let calendar = Calendar.current
        let currentDate = Date()
        return calendar.component(.day, from: currentDate)
    }
    
    // 去掉所有高度计算，让卡片自然适应内容
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 日历卡片
                VStack(spacing: 0) {
                    // 星期标签 - 使用LazyVGrid确保与日期网格间距一致
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                        ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 40, height: 20) // 高度减半，从40px改为20px
                                .padding(.vertical, 0)
                        }
                    }
                    .padding(.horizontal, 16) // 与日期网格保持相同的内边距
                    .padding(.top, 16) // 恢复顶部间距，让内容与卡片上沿有距离
                    .padding(.bottom, 4) // 底部保持4px的间距
                    .background(ColorManager.cardbackground)
                    
                    // 日期网格
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) { // 添加8px的垂直和水平间距
                        // 动态计算所需行数，只渲染需要的格子数量
                        let totalSlots = firstDayOfMonth + daysInMonth
                        let rows = Int(ceil(Double(totalSlots) / 7.0))
                        let itemCount = rows * 7
                        // 计算当前月份1号是周几，然后从对应的周几开始显示日期
                        ForEach(0..<itemCount, id: \.self) { index in
                            let adjustedIndex = index - firstDayOfMonth + 1
                            
                            if adjustedIndex >= 1 && adjustedIndex <= daysInMonth {
                                // 显示日期
                                DayCell(
                                    day: adjustedIndex,
                                    isToday: false, // 不再做特殊处理
                                    emotionRecord: currentMonthData[adjustedIndex],
                                    onDayTap: { day in
                                        let dayRecords = getDayRecords(for: day)
                                        print("点击日期 \(day)，找到 \(dayRecords.count) 篇日记")
                                        if dayRecords.count == 1 {
                                            // 只有一个日记，显示预览弹窗
                                            if let record = dayRecords.first {
                                                onJournalPreview(record)
                                            }
                                        } else if dayRecords.count > 1 {
                                            // 多个日记，显示选择浮窗
                                            print("设置 selectedDay: \(day), selectedDayRecords count: \(dayRecords.count)")
                                            selectedDay = day
                                            selectedDayRecords = dayRecords
                                            print("设置后确认 - selectedDay: \(selectedDay), selectedDayRecords count: \(selectedDayRecords.count)")
                                            
                                            // 延迟显示 sheet，确保状态完全更新
                                            DispatchQueue.main.async {
                                                showJournalSelector = true
                                            }
                                        }
                                    }
                                )
                            } else {
                                // 空白天数，不显示任何内容
                                Color.clear
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20) // 为日期最后一行和卡片底部添加padding
                }
                .background(ColorManager.cardbackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // 情绪占比卡片
                EmotionStatsCard(records: records, onEmotionTap: onEmotionTap)
                    .padding(.horizontal, 16)
                
                // 去掉这个Spacer，它导致底部间距过大
                // Spacer(minLength: 100)
            }
                                .padding(.top, 4) // 改为4px，与情绪模块保持一致
        }
        .background(ColorManager.sysbackground)
    }
    
    private func formatCurrentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: Date())
    }
}

// 日期单元格组件
struct DayCell: View {
    let day: Int
    let isToday: Bool
    let emotionRecord: ChatRecord?
    let onDayTap: (Int) -> Void // 添加点击回调
    
    var body: some View {
        ZStack {
            // 背景圆形
            Circle()
                .fill(backgroundColor)
                .frame(width: 40, height: 40)
            
            if let record = emotionRecord {
                // 有情绪记录：显示情绪icon，可点击
                Image(record.emotion?.iconName ?? "Happy")
                    .resizable()
                    .frame(width: 28, height: 28)
            } else {
                // 无情绪记录：显示日期数字
                Text("\(day)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .onTapGesture {
            if emotionRecord != nil {
                onDayTap(day)
            }
        }
    }
    
    // 背景颜色
    private var backgroundColor: Color {
        if let record = emotionRecord {
            // 有情绪记录：使用对应情绪的secondary颜色
            return emotionPrimaryColor(for: record.emotion)
        } else {
            // 无情绪记录：浅灰色
            return Color.gray.opacity(0.1)
        }
    }
    
    // 获取情绪的primary颜色
    private func emotionPrimaryColor(for emotion: EmotionType?) -> Color {
        guard let emotion = emotion else { return Color.gray.opacity(0.1) }
        
        switch emotion {
        case .happy:
            return ColorManager.Happy.primary
        case .sad:
            return ColorManager.Sad.primary
        case .angry:
            return ColorManager.Angry.primary
        case .peaceful:
            return ColorManager.Peaceful.primary
        case .happiness:
            return ColorManager.Happiness.primary
        case .unhappy:
            return ColorManager.Unhappy.primary
        }
    }
}

// 情绪占比卡片组件
struct EmotionStatsCard: View {
    let records: [ChatRecord]
    let onEmotionTap: (EmotionType) -> Void // 添加点击回调
    
    // 计算当月各情绪的占比
    private var emotionStats: [(emotion: EmotionType, count: Int, percentage: Double)] {
        // 直接使用传入的 records（外部已按所选月份过滤）
        var emotionCounts: [EmotionType: Int] = [:]
        for record in records {
            if let emotion = record.emotion {
                emotionCounts[emotion, default: 0] += 1
            }
        }

        // 以有情绪的记录数作为分母
        let totalCount = emotionCounts.values.reduce(0, +)

        // 转换为数组并计算百分比
        return emotionCounts.map { emotion, count in
            let percentage = totalCount > 0 ? Double(count) / Double(totalCount) * 100 : 0
            return (emotion: emotion, count: count, percentage: percentage)
        }
        .sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
        VStack(spacing: 28) {
            // 情绪进度条
            ForEach(emotionStats, id: \.emotion) { stat in
                EmotionProgressBar(
                    emotion: stat.emotion,
                    percentage: stat.percentage,
                    count: stat.count,
                    onEmotionTap: onEmotionTap
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(ColorManager.cardbackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 情绪进度条组件
struct EmotionProgressBar: View {
    let emotion: EmotionType
    let percentage: Double
    let count: Int
    let onEmotionTap: (EmotionType) -> Void // 添加点击回调
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 情绪icon
            Image(emotion.iconName)
                .resizable()
                .frame(width: 48, height: 48)
            
            // 进度条模块（整个模块可点击）
            VStack(alignment: .leading, spacing: 4) {
                // 进度条在上方
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景条
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // 进度填充
                        RoundedRectangle(cornerRadius: 4)
                            .fill(emotionColor)
                            .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                    }
                }
                .frame(height: 8)
                
                // 下方：情绪文字和百分比
                HStack {
                    // 情绪文字在左下角
                    Text(emotion.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(emotionSecondaryColor)
                    
                    Spacer()
                    
                    // 百分比在右下角
                    Text("\(Int(percentage))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(emotionSecondaryColor)
                }
            }
            .contentShape(Rectangle()) // 让整个区域可点击
            .onTapGesture {
                onEmotionTap(emotion)
            }
            
            Spacer()
        }
        .frame(height: 42)
    }
    
    // 获取情绪对应的颜色
    private var emotionColor: Color {
        switch emotion {
        case .happy:
            return ColorManager.Happy.primary
        case .sad:
            return ColorManager.Sad.primary
        case .angry:
            return ColorManager.Angry.primary
        case .peaceful:
            return ColorManager.Peaceful.primary
        case .happiness:
            return ColorManager.Happiness.primary
        case .unhappy:
            return ColorManager.Unhappy.primary
        }
    }
    
    // 获取情绪的secondary颜色
    private var emotionSecondaryColor: Color {
        switch emotion {
        case .happy:
            return ColorManager.Happy.secondary
        case .sad:
            return ColorManager.Sad.secondary
        case .angry:
            return ColorManager.Angry.secondary
        case .peaceful:
            return ColorManager.Peaceful.secondary
        case .happiness:
            return ColorManager.Happiness.secondary
        case .unhappy:
            return ColorManager.Unhappy.secondary
        }
    }
}

// 空状态视图组件
struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                // 图标
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.secondary)
                
                // 文案
                Text("本月暂无数据")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorManager.sysbackground)
    }
}

// 日记选择浮窗组件
struct JournalSelectorSheet: View {
    @Binding var day: Int
    @Binding var records: [ChatRecord]
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath // 添加导航路径绑定
    
    // 预览弹窗状态 - 使用 item 方式
    @State private var currentPreviewRecord: ChatRecord?
    @State private var hasImagesInPreview = false // 新增：预览中是否有图片
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text(formatDate(day))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .onAppear {
                        print("JournalSelectorSheet 显示: day=\(day), records count=\(records.count)")
                    }
                
                // 日记列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(records) { record in
                            JournalSelectorRow(record: record, showDate: false)
                                .onTapGesture {
                                    // 显示预览弹窗 - 使用 item 方式
                                    currentPreviewRecord = record
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(item: $currentPreviewRecord) { record in
            FloatingModalView(
                currentEmotion: EmotionData.emotions.first { $0.emotionType == record.emotion } ?? EmotionData.emotions[3],
                mode: .preview,
                previewRecord: record,
                onDelete: {
                    print("🗑️ 日记选择器 - onDelete 回调被调用")
                    print("   要删除的 record.id: \(record.id.uuidString)")
                    print("   要删除的 record.backendId: \(record.backendId ?? -1)")
                    
                    // 从当前记录列表中移除
                    records.removeAll { $0.id == record.id }
                    print("   ✅ 已从当前记录列表中移除")
                    
                    // 关闭预览弹窗
                    currentPreviewRecord = nil
                    isPresented = false
                    print("   ✅ 已关闭预览弹窗")
                },
                onEdit: {
                    // 开始编辑 - 不关闭弹窗，只是切换到编辑模式
                    print("🔄 日记选择器 - 开始编辑日记")
                    // 不关闭弹窗，让FloatingModalView内部处理编辑模式切换
                },
                onEditComplete: {
                    // 编辑完成 - 关闭弹窗并重新加载数据
                    print("🔄 日记选择器 - 编辑完成")
                    
                    // 重新加载本地数据
                    let updatedRecords = RecordManager.loadAll()
                    print("   🔄 重新加载了 \(updatedRecords.count) 条记录")
                    
                    // 筛选出指定日期的记录
                    let calendar = Calendar.current
                    let today = Date()
                    let month = calendar.component(.month, from: today)
                    let year = calendar.component(.year, from: today)
                    
                    let dayRecords = updatedRecords.filter { record in
                        let recordDay = calendar.component(.day, from: record.date)
                        let recordMonth = calendar.component(.month, from: record.date)
                        let recordYear = calendar.component(.year, from: record.date)
                        return recordDay == day && recordMonth == month && recordYear == year
                    }
                    
                    // 更新当前记录列表
                    records = dayRecords
                    print("   ✅ 已更新第\(day)天的记录，数量: \(records.count)")
                    
                    // 关闭预览弹窗
                    currentPreviewRecord = nil
                    isPresented = false
                    print("   ✅ 已关闭预览弹窗")
                },
                isPresented: .constant(false), // 使用 sheet(item:) 时不需要这个绑定
                navigationPath: $navigationPath
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
            .onChange(of: records) { newRecords in
                // 当记录列表为空时，自动关闭弹窗
                if newRecords.isEmpty {
                    print("🔄 日记选择器记录为空，自动关闭弹窗")
                    isPresented = false
                }
            }
        }
    }
    
    // 格式化日期显示
    private func formatDate(_ day: Int) -> String {
        let calendar = Calendar.current
        let currentDate = Date()
        let month = calendar.component(.month, from: currentDate)
        return "\(month)月\(day)日"
    }
}

// 日记选择行组件
struct JournalSelectorRow: View {
    let record: ChatRecord
    let showDate: Bool // 是否显示日期
    
    var body: some View {
        HStack(spacing: 12) {
            // 情绪图标
            Image(record.emotion?.iconName ?? "Happy")
                .resizable()
                .frame(width: 32, height: 32)
            
            HStack {
                // 正文内容（只显示一行）- 只有内容不为空时才显示
                if !record.plainTextContent.isEmpty {
                    Text(record.plainTextContent)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Spacer()
            }
            
            Spacer()
            
            // 时间（根据showDate决定显示格式）
            Text(showDate ? formatDateTime(record.date) : formatTime(record.date))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ColorManager.cardbackground)
        .cornerRadius(12)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// 情绪日记列表弹窗组件
struct EmotionJournalListSheet: View {
    let emotion: EmotionType
    let selectedDate: Date // 添加选择的日期参数
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    
    // 预览弹窗状态
    @State private var currentPreviewRecord: ChatRecord?
    @State private var hasImagesInPreview = false // 新增：预览中是否有图片
    // 本地数据状态
    @State private var localRecords: [ChatRecord] = []
    
    // 筛选出该情绪在指定月份的日记
    private var emotionRecords: [ChatRecord] {
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)
        
        let filteredRecords = localRecords.filter { record in
            guard record.emotion == emotion else { return false }
            
            let recordMonth = calendar.component(.month, from: record.date)
            let recordYear = calendar.component(.year, from: record.date)
            
            return recordMonth == selectedMonth && recordYear == selectedYear
        }
        .sorted { $0.date > $1.date }
        
        // 如果筛选后的记录为空，自动关闭弹窗
        if filteredRecords.isEmpty && !localRecords.isEmpty {
            DispatchQueue.main.async {
                print("🔄 情绪日记列表为空，自动关闭弹窗")
                isPresented = false
            }
        }
        
        return filteredRecords
    }
    
    // 加载本地数据
    private func loadLocalRecords() {
        localRecords = RecordManager.loadAll()
        print("🔄 EmotionJournalListSheet 加载了 \(localRecords.count) 条记录")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("\(emotion.displayName)日记")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .onAppear {
                        // 加载本地数据
                        loadLocalRecords()
                        let calendar = Calendar.current
                        let month = calendar.component(.month, from: selectedDate)
                        let year = calendar.component(.year, from: selectedDate)
                        print("EmotionJournalListSheet 显示: emotion=\(emotion.displayName), 月份=\(month)月\(year)年, records count=\(emotionRecords.count)")
                    }
                
                // 日记列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(emotionRecords) { record in
                            JournalSelectorRow(record: record, showDate: true)
                                .onTapGesture {
                                    // 显示预览弹窗
                                    currentPreviewRecord = record
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(item: $currentPreviewRecord) { record in
            FloatingModalView(
                currentEmotion: EmotionData.emotions.first { $0.emotionType == record.emotion } ?? EmotionData.emotions[3],
                mode: .preview,
                previewRecord: record,
                onDelete: {
                    print("🗑️ 情绪日记列表 - onDelete 回调被调用")
                    print("   要删除的 record.id: \(record.id.uuidString)")
                    print("   要删除的 record.backendId: \(record.backendId ?? -1)")
                    
                    // 重新加载本地数据
                    loadLocalRecords()
                    print("   ✅ 已重新加载本地数据")
                    
                    // 关闭预览弹窗
                    currentPreviewRecord = nil
                    isPresented = false
                    print("   ✅ 已关闭预览弹窗")
                },
                onEdit: {
                    // 开始编辑 - 不关闭弹窗，只是切换到编辑模式
                    print("🔄 情绪日记列表 - 开始编辑日记")
                    // 不关闭弹窗，让FloatingModalView内部处理编辑模式切换
                },
                onEditComplete: {
                    // 编辑完成 - 关闭弹窗
                    print("🔄 情绪日记列表 - 编辑完成")
                    // 重新加载本地数据以显示编辑后的内容
                    loadLocalRecords()
                    print("   ✅ 已重新加载本地数据")
                    // 关闭预览弹窗
                    currentPreviewRecord = nil
                    print("   ✅ 已关闭预览弹窗")
                },
                isPresented: .constant(true),
                navigationPath: $navigationPath
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
    }
}


