import SwiftUI

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
    
    // 月份选择器相关状态
    @State private var selectedDate = Date()
    @State private var showYearPicker = false
    
    // 日记选择相关状态
    @State private var showJournalSelector = false
    @State private var selectedDay = 0
    @State private var selectedDayRecords: [ChatRecord] = []
    
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthPickerView(
                    selectedDate: $selectedDate,
                    showYearPicker: $showYearPicker
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { 
            print("🔍 ChatHistoryView - onAppear")
            
            // 正常加载本地数据
            loadRecords()
            print("   records count: \(records.count)")
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
                                sheetManager: actionSheetManager,
                                record: record,
                                onTap: {
                                    // 确保使用最新的数据
                                    if let backendId = record.backendId {
                                        // 先检查缓存，如果缓存存在就直接使用
                                        Task {
                                            // 1. 首先尝试从缓存获取数据
                                            if let cachedRecord = JournalDetailService.shared.getCachedJournalDetail(journalId: backendId) {
                                                print("✅ 使用缓存的日记详情: journal_\(backendId)")
                                                await MainActor.run {
                                                    navigationPath.append(AppRoute.journalDetail(id: backendId))
                                                }
                                                return
                                            }
                                            
                                            // 2. 缓存不存在，从后端获取
                                            print("🔍 缓存不存在，从后端获取日记详情: journal_\(backendId)")
                                            do {
                                                let detailRecord = try await JournalDetailService.shared.fetchAndCacheJournalDetail(journalId: backendId)
                                                await MainActor.run {
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
    
    private func loadRecordsAsync() async {
        // 设置加载状态
        await MainActor.run {
            isLoading = true
        }
        
        // 在后台线程加载数据
        let loadedRecords = await Task.detached {
            RecordManager.loadAll().sorted { $0.date > $1.date }
        }.value
        
        // 在主线程更新UI
        await MainActor.run {
            records = loadedRecords
            isLoading = false
            print("🔍 ChatHistoryView - 异步加载完成，records count: \(records.count)")
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
}

// 日记卡片组件
struct JournalEntryCard: View {
    @ObservedObject var sheetManager: ActionSheetManager
    let record: ChatRecord
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
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
                        .frame(width: 48, height: 48)
                    
                    // 日期和时间
                    HStack(spacing: 8) {
                        Text(formatDate(record.date))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(record.date))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // More按钮 - 移到右上角
                    Button(action: { 
                        print("🔘 More按钮被点击")
                        sheetManager.show(onEdit: onEdit, onDelete: onDelete)
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 60, height: 60) // 增大到 60x60
                            .rotationEffect(.degrees(90))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // 间隔 8px
                Spacer().frame(height: 8)
                
                // 2. 日记标题
                Text(record.title ?? "无标题")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                
                // 间隔 16px
                Spacer().frame(height: 16)
                
                // 3. 日记正文
                Text(record.plainTextContent)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
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
    @Binding var navigationPath: NavigationPath // 添加导航路径绑定
    
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
                                            // 只有一个日记，直接跳转
                                            if let record = dayRecords.first, let backendId = record.backendId {
                                                // 导航到日记详情
                                                navigationPath.append(AppRoute.journalDetail(id: backendId))
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
                EmotionStatsCard(records: records)
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
        VStack(spacing: 16) {
            // 情绪进度条
            VStack(spacing: 12) {
                ForEach(emotionStats, id: \.emotion) { stat in
                    EmotionProgressBar(
                        emotion: stat.emotion,
                        percentage: stat.percentage,
                        count: stat.count
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景条 - 使用父容器的完整宽度
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(emotionColor, lineWidth: 1)
                    )
                    .frame(width: geometry.size.width, height: 52)
                
                // 进度填充 - 根据百分比计算宽度，但有最小宽度
                let minWidth: CGFloat = 100 // 足够容纳icon和文字的最小宽度
                let maxWidth = geometry.size.width - 4 // 减去左右各2px的padding
                let progressWidth = max(minWidth, maxWidth * CGFloat(percentage / 100))
                
                RoundedRectangle(cornerRadius: 25)
                    .fill(emotionColor)
                    .frame(width: progressWidth, height: 48)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                
                // 内容层（icon和百分比）- 根据彩色进度条宽度精确定位
                HStack {
                    // 情绪icon - 更大的圆圈底色，使用card底色
                    ZStack {
                        Circle()
                            .fill(ColorManager.cardbackground)
                            .frame(width: 44, height: 44)
                        
                        Image(emotion.iconName)
                            .resizable()
                            .frame(width: 42, height: 42)
                    }
                    .padding(.leading, 6)
                    
                    Spacer()
                    
                    // 百分比 - 在彩色进度条内部，使用secondary颜色
                    Text("\(Int(percentage))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(emotionSecondaryColor)
                        .padding(.trailing, 8)
                }
                .frame(width: progressWidth, height: 52)
                .zIndex(1)
            }
        }
        .frame(height: 52) // 给GeometryReader设置固定高度
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
                            JournalSelectorRow(record: record)
                                                            .onTapGesture {
                                // 处理日记选择，导航到日记详情
                                if let backendId = record.backendId {
                                    navigationPath.append(AppRoute.journalDetail(id: backendId))
                                }
                                isPresented = false
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
    
    var body: some View {
        HStack(spacing: 12) {
            // 情绪图标
            Image(record.emotion?.iconName ?? "Happy")
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                // 标题
                Text(record.title ?? "无标题")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                
                // 时间
                Text(formatTime(record.date))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
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
}
