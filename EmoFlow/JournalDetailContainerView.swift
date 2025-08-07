import SwiftUI

struct JournalDetailContainerView: View {
    let journalId: Int
    @State private var record: ChatRecord?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isForceRefreshing = false // 添加强制刷新标志
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("正在加载日记详情...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("加载失败")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let record = record {
                ChatrecordDetailView(
                    record: record,
                    onSave: { newSummary in
                        // 保存逻辑
                        record.summary = newSummary
                    },
                    navigationPath: $navigationPath
                )
                .id(record.id) // 添加id确保数据更新时重新渲染
            } else {
                // 添加一个默认状态，防止空白页面
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("日记详情")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("正在准备显示...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)  // 隐藏系统默认的返回按钮
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // 统一使用 removeLast() 返回
                    if !navigationPath.isEmpty {
                        navigationPath.removeLast()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(getEmotionSecondaryColor())
                }
            }
        }
        .onAppear {
            loadJournalDetail()
        }
        .onReceive(NotificationCenter.default.publisher(for: .journalUpdated)) { notification in
            if let updatedJournalId = notification.object as? Int, updatedJournalId == journalId {
                print("🔄 收到日记更新通知，重新加载数据: journal_\(journalId)")
                // 设置强制刷新标志
                isForceRefreshing = true
                // 先清除缓存，确保获取最新数据
                JournalDetailService.shared.clearDetailCache(journalId: journalId)
                // 直接调用，避免嵌套异步
                loadJournalDetail(forceRefresh: true)
            }
        }
    }
    
    // 根据当前记录的情绪获取次要颜色
    private func getEmotionSecondaryColor() -> Color {
        guard let record = record, let emotion = record.emotion else { 
            return .primary 
        }
        
        // 根据情绪类型返回对应的 secondary 颜色
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
    
    private func loadJournalDetail(forceRefresh: Bool = false) {
        print("🔍 loadJournalDetail 被调用 - forceRefresh: \(forceRefresh), journalId: \(journalId)")
        
        // 如果正在强制刷新，避免重复调用
        if isForceRefreshing && !forceRefresh {
            print("⏸️ 正在强制刷新中，跳过正常加载")
            return
        }
        
        Task {
            // 如果不是强制刷新，先尝试从缓存获取数据
            if !forceRefresh {
                if let cachedRecord = JournalDetailService.shared.getCachedJournalDetail(journalId: journalId) {
                    print("✅ 使用缓存的日记详情: journal_\(journalId)")
                    await MainActor.run {
                        self.record = cachedRecord
                        self.isLoading = false
                    }
                    return
                }
            }
            
            // 强制刷新或缓存不存在，从后端获取
            print("🔍 \(forceRefresh ? "强制刷新" : "缓存不存在")，从后端获取日记详情: journal_\(journalId)")
            do {
                let detailRecord: ChatRecord
                if forceRefresh {
                    // 强制刷新时：先获取最新数据，然后缓存
                    detailRecord = try await JournalDetailService.shared.fetchJournalDetailWithoutCache(journalId: journalId)
                    // 手动缓存最新数据
                    let cacheKey = "journal_detail_\(journalId)"
                    let cacheData = CacheData(record: detailRecord, timestamp: Date())
                    if let data = try? JSONEncoder().encode(cacheData) {
                        UserDefaults.standard.set(data, forKey: cacheKey)
                        print("✅ 强制刷新后缓存最新数据: \(cacheKey)")
                    }
                } else {
                    // 正常获取并缓存
                    detailRecord = try await JournalDetailService.shared.fetchAndCacheJournalDetail(journalId: journalId)
                }
                // 使用 DispatchQueue.main.async 确保在主线程上更新状态
                DispatchQueue.main.async {
                    // 强制刷新时总是更新数据
                    if forceRefresh {
                        print("🔄 强制刷新更新日记详情数据 - 新summary长度: \(detailRecord.summary.count)")
                        self.record = detailRecord
                    } else {
                        // 避免重复更新相同的数据
                        if self.record?.id != detailRecord.id || self.record?.summary != detailRecord.summary {
                            print("🔄 更新日记详情数据 - 旧summary长度: \(self.record?.summary.count ?? 0), 新summary长度: \(detailRecord.summary.count)")
                            self.record = detailRecord
                        } else {
                            print("⏸️ 数据未变化，跳过更新")
                        }
                    }
                    self.isLoading = false
                    // 重置强制刷新标志
                    if forceRefresh {
                        self.isForceRefreshing = false
                        print("✅ 强制刷新完成，重置标志")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
} 