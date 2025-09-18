import SwiftUI

// MARK: - 浮窗模式枚举
enum FloatingModalMode {
    case create    // 创建新日记
    case preview   // 预览已有日记
    case edit      // 编辑已有日记
}

// MARK: - 浮窗组件
struct FloatingModalView: View {
    let currentEmotion: EmotionData
    let mode: FloatingModalMode
    let previewRecord: ChatRecord?
    let onDelete: (() -> Void)?
    let onEdit: (() -> Void)? // 开始编辑回调
    let onEditComplete: (() -> Void)? // 编辑完成回调

    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    
    @State private var inputText = ""
    @State private var showRichTextToolbar = false
    @State private var isCreatingJournal = false
    @State private var isEditingJournal = false
    @State private var isDeletingJournal = false
    @FocusState private var isTextEditorFocused: Bool
    @State private var hasImages = false
    
    // 图片管理
    @StateObject private var imageManager: ImageManager
    
    // 初始化方法
    init(currentEmotion: EmotionData, mode: FloatingModalMode, previewRecord: ChatRecord? = nil, onDelete: (() -> Void)? = nil, onEdit: (() -> Void)? = nil, onEditComplete: (() -> Void)? = nil, isPresented: Binding<Bool>, navigationPath: Binding<NavigationPath>) {
        self.currentEmotion = currentEmotion
        self.mode = mode
        self.previewRecord = previewRecord
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.onEditComplete = onEditComplete
        self._isPresented = isPresented
        self._navigationPath = navigationPath
        
        print("🔍 FloatingModalView 初始化")
        print("   mode: \(mode)")
        print("   previewRecord 是否为 nil: \(previewRecord == nil)")
        if let record = previewRecord {
            print("   record.id: \(record.id.uuidString)")
            print("   record.summary: '\(record.summary)'")
            print("   record.summary 长度: \(record.summary.count)")
            print("   record.plainTextContent: '\(record.plainTextContent)'")
        }
        
        // 如果是预览模式或编辑模式，初始化文本内容
        if (mode == .preview || mode == .edit), let record = previewRecord {
            self._inputText = State(initialValue: record.plainTextContent)
            print("   inputText 初始化为: '\(record.plainTextContent)'")
        }
        
        // 初始化 ImageManager
        if mode == .edit, let record = previewRecord {
            print("📸 FloatingModalView - 编辑模式初始化")
            print("📸 FloatingModalView - 图片IDs: \(record.images ?? [])")
            print("📸 FloatingModalView - 图片URLs: \(record.image_urls ?? [])")
            self._imageManager = StateObject(wrappedValue: ImageManager(
                existingImageIds: record.images,
                existingImageUrls: record.image_urls
            ))
        } else {
            print("📸 FloatingModalView - 非编辑模式初始化")
            self._imageManager = StateObject(wrappedValue: ImageManager())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部间距 28px
            Spacer()
                .frame(height: 28)
            
            // 正文区域 - 可滚动
            if mode == .create || mode == .edit || (mode == .preview && isEditingJournal) {
                // 创建模式或编辑模式：可编辑的TextEditor + 图片管理
                ScrollView {
                    VStack(spacing: 0) {
                        // 文本编辑区域
                        TextEditor(text: $inputText)
                            .font(.system(size: 16, weight: .light))
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .focused($isTextEditorFocused)
                            .overlay(
                                Group {
                                    if inputText.isEmpty {
                                        VStack {
                                            HStack {
                                                Text(mode == .create ? getEmotionPlaceholder() : "编辑日记内容")
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 16, weight: .light))
                                                    .padding(.leading, 4)
                                                    .padding(.top, 8)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                        .allowsHitTesting(false)
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                        
                        // 图片管理区域
                        ImageGridView(imageManager: imageManager)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }
                }
            } else {
                // 预览模式：可滚动的内容显示
                let content = previewRecord?.plainTextContent ?? ""
                let displayContent = content.isEmpty ? "当时没记录什么哦，可以点击编辑添加内容" : content
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 正文内容
                        Text(displayContent)
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(content.isEmpty ? .secondary : .primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        
                        // 图片显示区域（如果有图片）
                        if let record = previewRecord, let imageURLs = record.image_urls, !imageURLs.isEmpty {
                            JournalImagesView(imageURLs: imageURLs)
                                .onAppear {
                                    print("🔍 FloatingModalView - 显示图片，数量: \(imageURLs.count)")
                                    print("🔍 FloatingModalView - 图片URLs: \(imageURLs)")
                                    hasImages = true
                                }
                        }
                    }
                    .onAppear {
                        print("🔍 FloatingModalView 预览模式 onAppear")
                        print("   previewRecord 是否为 nil: \(previewRecord == nil)")
                        print("   mode: \(mode)")
                        print("   日记内容: '\(content)'")
                        print("   内容长度: \(content.count)")
                        print("   原始summary: '\(previewRecord?.summary ?? "nil")'")
                        print("   summary 长度: \(previewRecord?.summary.count ?? 0)")
                        print("   summary 是否为空: \(previewRecord?.summary.isEmpty ?? true)")
                        print("   plainTextContent: '\(previewRecord?.plainTextContent ?? "nil")'")
                        print("   情绪: \(previewRecord?.emotion?.rawValue ?? "nil")")
                        print("   record.id: \(previewRecord?.id.uuidString ?? "nil")")
                        print("   record.backendId: \(previewRecord?.backendId ?? -1)")
                        print("   图片URLs: \(previewRecord?.image_urls ?? [])")
                        
                        // 检查是否有图片
                        hasImages = (previewRecord?.image_urls?.isEmpty == false)
                        print("   hasImages: \(hasImages)")
                        
                        // 验证内容是否为空或只有空白字符
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedContent.isEmpty {
                            print("⚠️ 警告：内容为空或只有空白字符")
                        }
                    }
                }
            }
            
            // 键盘上方的toolbar
            if showRichTextToolbar || mode == .preview || mode == .edit {
                HStack {
                    // 左侧：情绪icon和时间日期
                    HStack(spacing: 8) {
                        // 情绪icon
                        Image(currentEmotion.assetName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                        
                        // 时间日期
                        Text(getDisplayDateTime())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 右侧：根据模式显示不同按钮
                    if mode == .create {
                        // 创建模式：聊聊 + 记录按钮
                        HStack(spacing: 4) {
                            // 聊聊按钮 - 加载时隐藏
                            if !isCreatingJournal {
                                Button(action: startChat) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "message")
                                            .font(.system(size: 20, weight: .semibold))
                                        Text("聊聊")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(currentEmotion.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                                
                                // 垂直分割线
                                Rectangle()
                                    .fill(currentEmotion.secondary.opacity(0.3))
                                    .frame(width: 2, height: 12)
                            }
                            
                            // 记录按钮
                            Button(action: createNewJournal) {
                                if isCreatingJournal {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .progressViewStyle(CircularProgressViewStyle(tint: currentEmotion.secondary))
                                        Text("记录中...")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(currentEmotion.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 20, weight: .semibold))
                                        Text("记录")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(currentEmotion.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                            }
                            .disabled(isCreatingJournal)
                        }
                    } else if (mode == .preview && isEditingJournal) || mode == .edit {
                        // 编辑模式：取消 + 保存按钮
                        HStack(spacing: 4) {
                            // 取消按钮 - 只在非保存loading状态下显示
                            if !isCreatingJournal {
                                Button(action: cancelEdit) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 20, weight: .semibold))
                                        Text("取消")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                                
                                // 垂直分割线
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 2, height: 12)
                            }
                            
                            // 保存按钮
                            Button(action: saveEditedJournal) {
                                if isCreatingJournal {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .progressViewStyle(CircularProgressViewStyle(tint: currentEmotion.secondary))
                                        Text("保存中...")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(currentEmotion.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20, weight: .semibold))
                                        Text("保存")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(currentEmotion.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                            }
                            .disabled(isCreatingJournal)
                        }
                    } else {
                        // 预览模式：删除 + 编辑按钮
                        HStack(spacing: 4) {
                            // 删除按钮
                            Button(action: deleteJournal) {
                                HStack(spacing: 8) {
                                    if isDeletingJournal {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "trash")
                                            .font(.system(size: 20, weight: .semibold))
                                    }
                                    Text(isDeletingJournal ? "删除中..." : "删除")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(currentEmotion.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .disabled(isDeletingJournal)
                            
                            // 编辑按钮 - 只在非删除loading状态下显示
                            if !isDeletingJournal {
                                // 垂直分割线
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 2, height: 12)
                                
                                // 编辑按钮
                                Button(action: startEdit) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 20, weight: .semibold))
                                        Text("编辑")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(currentEmotion.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            print("🔍 FloatingModalView onAppear")
            print("   mode: \(mode)")
            print("   previewRecord 是否为 nil: \(previewRecord == nil)")
            print("   previewRecord?.plainTextContent: '\(previewRecord?.plainTextContent ?? "nil")'")
            
            if mode == .create {
                // 创建模式：自动聚焦并显示toolbar
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextEditorFocused = true
                    showRichTextToolbar = true
                }
            } else if mode == .edit {
                // 编辑模式：自动聚焦
                print("📸 FloatingModalView - 编辑模式 onAppear")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextEditorFocused = true
                    showRichTextToolbar = true
                }
            } else {
                // 预览模式：直接显示toolbar
                showRichTextToolbar = true
                print("🔍 预览模式：toolbar 已显示")
            }
        }
    }
    
    // 获取当前时间日期的格式化字符串
    private func getCurrentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: Date())
    }
    
    // 获取显示时间（根据模式显示不同时间）
    private func getDisplayDateTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日 HH:mm"
        
        if mode == .preview, let record = previewRecord {
            // 预览模式：显示日记的创建时间
            return formatter.string(from: record.date)
        } else {
            // 创建模式：显示当前时间
            return formatter.string(from: Date())
        }
    }
    
    // 开始聊天
    private func startChat() {
        // 关闭弹窗
        isPresented = false
        
        // 跳转到聊天页面
        let emotionType = currentEmotion.emotionType
        let chatMessage = getChatInitialMessage(emotionType)
        navigationPath.append(AppRoute.chat(emotion: emotionType, initialMessage: chatMessage))
    }
    
    // 获取聊天初始消息
    private func getChatInitialMessage(_ emotionType: EmotionType) -> String {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedInput.isEmpty {
            // 用户没有输入内容，使用默认格式
            return "我现在感觉到\(emotionType.displayName)"
        } else {
            // 用户输入了内容，直接使用用户输入的内容
            return trimmedInput
        }
    }
    
    // 获取情绪对应的placeholder文本
    private func getEmotionPlaceholder() -> String {
        switch currentEmotion.emotionType {
        case .angry:
            return "写下来，让情绪有个出口。"
        case .happy:
            return "记录一下开心的事情吧。"
        case .happiness:
            return "把这份被爱感受留下来～"
        case .unhappy:
            return "写写发生了什么，或许会轻松些。"
        case .sad:
            return "说一说心里的委屈，也没关系。"
        case .peaceful:
            return "这一刻的平静，也值得被记住。"
        }
    }
    
    // 删除日记
    private func deleteJournal() {
        print("🗑️ deleteJournal 函数被调用")
        
        guard let record = previewRecord else {
            print("❌ deleteJournal: previewRecord 为 nil")
            return
        }
        
        print("🗑️ deleteJournal 被调用")
        print("   record.id: \(record.id.uuidString)")
        print("   record.backendId: \(record.backendId ?? -1)")
        
        // 设置删除loading状态
        isDeletingJournal = true
        print("   ✅ 已设置删除loading状态: \(isDeletingJournal)")
        
        // 先删除本地记录
        RecordManager.delete(record)
        print("   ✅ 已删除本地记录")
        
        // 调用后端删除API
        if let backendId = record.backendId {
            Task {
                do {
                    let success = try await JournalDeleteService.shared.deleteJournal(journalId: backendId)
                    if success {
                        print("✅ 后端日记删除成功")
                        
                        // 发送删除通知，通知其他组件更新
                        await MainActor.run {
                            NotificationCenter.default.post(name: .journalDeleted, object: nil)
                            print("   ✅ 已发送日记删除通知")
                        }
                    } else {
                        print("❌ 后端日记删除失败")
                    }
                } catch {
                    print("❌ 后端日记删除失败: \(error)")
                }
                
                // 无论成功失败，都要关闭弹窗
                await MainActor.run {
                    isDeletingJournal = false
                    // 通过 onDelete 回调关闭弹窗
                    onDelete?()
                    print("   ✅ 已调用 onDelete 回调关闭弹窗")
                }
            }
        } else {
            print("⚠️ 无法删除后端日记：缺少backendId")
            // 没有backendId，直接关闭弹窗
            isDeletingJournal = false
            onDelete?()
            print("   ✅ 已调用 onDelete 回调关闭弹窗")
        }
    }
    
    // 开始编辑
    private func startEdit() {
        print("📝 startEdit - 开始编辑模式")
        
        // 切换到编辑模式
        isEditingJournal = true
        
        // 重新加载现有图片
        if let record = previewRecord {
            print("📸 startEdit - 重新加载现有图片")
            print("📸 startEdit - 图片IDs: \(record.images ?? [])")
            print("📸 startEdit - 图片URLs: \(record.image_urls ?? [])")
            imageManager.loadExistingImages(from: record.images, imageUrls: record.image_urls)
        }
        
        // 通知父组件切换到编辑模式
        onEdit?()
        
        // 延迟唤起键盘，确保编辑模式已经激活
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextEditorFocused = true
        }
    }
    
    // 取消编辑
    private func cancelEdit() {
        // 重置编辑状态
        isEditingJournal = false
        // 恢复原始内容
        if let record = previewRecord {
            inputText = record.plainTextContent
        }
        // 通知父组件切换回预览模式
        onEdit?()
    }
    
    // 保存编辑的日记
    private func saveEditedJournal() {
        guard let record = previewRecord else { 
            print("❌ saveEditedJournal: previewRecord 为 nil")
            return 
        }
        
        // 获取编辑后的文本内容
        let content = inputText
        
        print("🔄 saveEditedJournal 开始")
        print("   原始内容: '\(record.plainTextContent)'")
        print("   编辑后内容: '\(content)'")
        print("   内容是否改变: \(record.plainTextContent != content)")
        print("   record.id: \(record.id)")
        print("   record.backendId: \(record.backendId ?? -1)")
        
        // 设置loading状态
        isCreatingJournal = true
        print("   ✅ 已设置 loading 状态: \(isCreatingJournal)")
        
        // 强制UI更新
        DispatchQueue.main.async {
            print("   🔄 强制UI更新，loading状态: \(self.isEditingJournal)")
        }
        
        // 调用日记更新服务（支持图片）
        Task {
            do {
                if let backendId = record.backendId {
                    print("   📡 开始调用更新API，journalId: \(backendId)")
                    
                    // 获取图片数据
                    let keepImageIds = imageManager.getKeepImageIds()
                    let addImageData = imageManager.getAddImageData()
                    
                    print("   📸 图片数据:")
                    print("      保留图片IDs: \(keepImageIds)")
                    print("      新增图片数量: \(addImageData.count)")
                    
                    let response = try await JournalUpdateWithImagesService.shared.updateJournal(
                        journalId: backendId,
                        content: content,
                        emotion: currentEmotion.emotionType,
                        keepImageIds: keepImageIds,
                        addImageData: addImageData
                    )
                    
                    print("   📡 API响应: \(response.status)")
                    if response.status == "success" {
                        print("✅ 日记更新成功")
                        print("   📸 更新后图片IDs: \(response.images ?? [])")
                        print("   📸 更新后图片URLs: \(response.image_urls ?? [])")
                        
                        // 刷新日记列表，确保数据同步
                        do {
                            print("   🔄 开始获取最新日记列表...")
                            let updatedJournals = try await JournalListService.shared.fetchJournals(limit: 100, offset: 0)
                            print("✅ 日记列表已同步，获取到 \(updatedJournals.count) 条日记")
                            
                            // 查找更新后的记录
                            print("   🔍 调试查找记录:")
                            print("      查找条件: record.id = \(record.id)")
                            print("      可用记录数量: \(updatedJournals.count)")
                            for (index, journal) in updatedJournals.prefix(5).enumerated() {
                                print("      记录\(index): id = \(journal.id), backendId = \(journal.backendId ?? -1)")
                            }
                            
                            if let updatedRecord = updatedJournals.first(where: { $0.id == record.id }) {
                                print("   🔍 找到更新后的记录:")
                                print("      新内容: '\(updatedRecord.plainTextContent)'")
                                print("      内容是否改变: \(record.plainTextContent != updatedRecord.plainTextContent)")
                            } else {
                                print("   ⚠️ 未找到更新后的记录")
                                // 尝试用backendId查找
                                if let updatedRecord = updatedJournals.first(where: { $0.backendId == record.backendId }) {
                                    print("   🔍 通过backendId找到记录:")
                                    print("      新内容: '\(updatedRecord.plainTextContent)'")
                                } else {
                                    print("   ❌ 通过backendId也找不到记录")
                                }
                            }
                            
                            // 保存到本地缓存
                            RecordManager.saveAll(updatedJournals)
                            print("✅ 已保存到本地缓存")
                            
                            // 数据同步完成后，在主线程更新UI并关闭弹窗
                            await MainActor.run {
                                print("   🎯 开始关闭弹窗...")
                                // 重置loading状态
                                isCreatingJournal = false
                                isEditingJournal = false
                                print("   ✅ 已重置 loading 状态")
                                // 发送编辑完成通知，通知其他组件更新
                                NotificationCenter.default.post(name: .journalUpdated, object: nil)
                                print("   ✅ 已发送日记更新通知")
                                // 关闭弹窗 - 通知父组件关闭
                                onEditComplete?()
                                print("   ✅ 已调用 onEditComplete 回调关闭弹窗")
                            }
                        } catch {
                            print("⚠️ 日记列表同步失败: \(error)")
                            
                            // 即使同步失败，也要重置loading状态并关闭弹窗
                            await MainActor.run {
                                isEditingJournal = false
                                onEdit?()
                            }
                        }
                    } else {
                        print("❌ 日记更新失败，状态: \(response.status)")
                    }
                } else {
                    print("⚠️ 无法更新日记：缺少backendId")
                }
                
            } catch {
                print("❌ 日记更新失败: \(error)")
                
                // 在主线程显示错误提示
                await MainActor.run {
                    // 重置loading状态
                    isEditingJournal = false
                    print("日记更新失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func createNewJournal() {
        // 获取文本内容
        var content = inputText
        
        // 创建模式：如果内容为空，使用兜底文本
        if mode == .create && content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            content = "感觉到\(currentEmotion.emotionType.displayName)"
            print("创建新日记：内容为空，使用兜底文本：\(content)")
        } else {
            print("创建新日记：\(content.isEmpty ? "空内容" : content)")
        }
        
        // 设置loading状态
        isCreatingJournal = true
        
        // 调用日记创建服务
        Task {
            do {
                // 获取图片数据
                let imageData = imageManager.getAddImageData()
                
                let response = try await JournalCreateService.shared.createJournal(
                    content: content,
                    emotion: currentEmotion.emotionType,
                    imageData: imageData.isEmpty ? nil : imageData
                )
                
                print("✅ 日记创建成功，ID: \(response.journal_id)")
                
                // 先刷新日记列表
                print("🔄 开始刷新日记列表...")
                do {
                    let newJournals = try await JournalListService.shared.fetchJournals(limit: 100, offset: 0)
                    print("✅ 日记列表刷新成功，获取到 \(newJournals.count) 条日记")
                    
                    // 保存到本地
                    RecordManager.saveAll(newJournals)
                    print("✅ 日记列表已保存到本地")
                    
                    // 在主线程更新UI并跳转
                    await MainActor.run {
                        // 关闭弹窗
                        isPresented = false
                        // 跳转到日记列表
                        navigationPath.append(AppRoute.journalList)
                        print("✅ 跳转到日记列表")
                    }
                    
                } catch {
                    print("❌ 日记列表刷新失败: \(error)")
                    // 即使刷新失败，也要跳转
                    await MainActor.run {
                        isPresented = false
                        navigationPath.append(AppRoute.journalList)
                        print("⚠️ 刷新失败，但仍跳转到日记列表")
                    }
                }
                
            } catch {
                print("❌ 日记创建失败: \(error)")
                
                // 在主线程显示错误提示
                await MainActor.run {
                    // 重置loading状态
                    isCreatingJournal = false
                    // 可以在这里添加错误提示
                    print("日记保存失败: \(error.localizedDescription)")
                }
            }
        }
    }
}
