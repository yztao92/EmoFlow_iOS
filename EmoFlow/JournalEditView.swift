import SwiftUI

struct JournalEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedEmotion: EmotionType
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @StateObject private var imageManager = ImageManager()
    
    // 创建成功后的回调
    var onJournalCreated: ((Int) -> Void)? = nil
    // 编辑成功后的回调
    var onJournalUpdated: ((Int) -> Void)? = nil
    // 是否为编辑模式
    var isEditMode: Bool = false
    // 编辑时的日记ID
    var editJournalId: Int? = nil
    // 编辑时的ChatRecord（用于加载现有图片）
    private var editRecord: ChatRecord? = nil
    
    // 情绪选项
    private let emotionOptions: [EmotionType] = [.angry, .sad, .unhappy, .peaceful, .happy, .happiness]
    
    init(initialEmotion: EmotionType = .peaceful, navigationPath: Binding<NavigationPath>, isEditMode: Bool = false, editJournalId: Int? = nil, initialTitle: String = "", initialContent: String = "", initialHTMLContent: String = "", emotionText: String? = nil) {
        self._selectedEmotion = State(initialValue: initialEmotion)
        // 创建模式时，优先使用传入的情绪文本，否则使用情绪数据名称
        let defaultTitle = isEditMode ? initialTitle : (emotionText ?? initialEmotion.emotionDataName)
        self._title = State(initialValue: defaultTitle)
        self._navigationPath = navigationPath
        
        // 处理初始内容
        if !initialHTMLContent.isEmpty {
            // 简单处理HTML内容，提取纯文本
            self._content = State(initialValue: initialHTMLContent.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
        } else {
            self._content = State(initialValue: initialContent)
        }
        

        
        self.isEditMode = isEditMode
        self.editJournalId = editJournalId
    }
    
    // 新增：从 ChatRecord 创建编辑视图的初始化方法
    init(record: ChatRecord, navigationPath: Binding<NavigationPath>) {
        self._selectedEmotion = State(initialValue: record.emotion ?? .peaceful)
        self._title = State(initialValue: record.title ?? "")
        self._navigationPath = navigationPath
        
        // 处理初始内容：从HTML提取纯文本
        if !record.summary.isEmpty {
            let content = record.summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            self._content = State(initialValue: content)
        } else {
            self._content = State(initialValue: "")
        }
        
        self.isEditMode = true
        self.editJournalId = record.backendId
        self.editRecord = record
    }
    
    // 在编辑模式下加载现有图片
    private func loadExistingImages() {
        if isEditMode, let record = editRecord {
            // 从ChatRecord中加载现有图片
            imageManager.loadExistingImages(from: record.images, imageUrls: record.image_urls)
            print("📸 JournalEditView - 加载现有图片: \(record.images?.count ?? 0) 张")
        }
    }
    
    // 在视图出现时加载现有图片
    private func onAppear() {
        loadExistingImages()
    }
    

    
    var body: some View {
        ZStack {
            // 背景
            CustomBackgroundView(
                style: BackgroundStyle.grid,
                emotionColor: getEmotionBackgroundColor()
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 编辑区域
                ScrollView {
                    VStack(spacing: 0) {
                        // 情绪选择
                        Button(action: {
                            switch selectedEmotion {
                            case .angry:
                                selectedEmotion = .sad
                            case .sad:
                                selectedEmotion = .unhappy
                            case .unhappy:
                                selectedEmotion = .peaceful
                            case .peaceful:
                                selectedEmotion = .happy
                            case .happy:
                                selectedEmotion = .happiness
                            case .happiness:
                                selectedEmotion = .angry
                            }
                        }) {
                            Image(selectedEmotion.iconName)
                                .resizable()
                                .frame(width: 128, height: 128)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // 标题输入
                        TextField("给这段心情起个标题...", text: $title)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .background(Color.clear)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 8) // 添加title到正文的间距
                        
                        // 文本内容输入
                        VStack(alignment: .leading, spacing: 0) {
                            TextEditor(text: $content)
                                .font(.system(size: 16, weight: .light))
                                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 400)
                                .overlay(
                                    Group {
                                        if content.isEmpty {
                                            VStack {
                                                HStack {
                                                    Text("写下你的心情...")
                                                        .foregroundColor(.secondary)
                                                        .font(.system(size: 16, weight: .light))
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .allowsHitTesting(false)
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal, 16)
                        
                        // 图片管理区域
                        ImageGridView(imageManager: imageManager)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .onAppear {
                                print("📝 JournalEditView - ImageGridView added to view")
                            }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 0)
                }
                

            }
            
            // Loading 覆盖层
            if isSaving {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("正在保存...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.7))
                )
                .allowsHitTesting(false)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // 隐藏系统默认的返回按钮
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(getEmotionSecondaryColor())
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveJournal()
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(getEmotionSecondaryColor())
                }
                .disabled(title.isEmpty || content.isEmpty || isSaving)
            }
        }
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            onAppear()
        }



    }
    

    

    

    
    // 简化的保存逻辑
    private func saveJournal() {
        // 防止重复保存
        guard !isSaving else { return }
        
        // 隐藏键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 显示 loading 状态
        isSaving = true
        
        // 直接获取文本内容并保存
        saveJournalWithContent(content)
    }
    

    
    // 根据日记情绪获取对应的背景颜色
    private func getEmotionBackgroundColor() -> Color? {
        // 根据情绪类型返回对应的 light 颜色
        switch selectedEmotion {
        case .happy:
            return ColorManager.Happy.light
        case .sad:
            return ColorManager.Sad.light
        case .angry:
            return ColorManager.Angry.light
        case .peaceful:
            return ColorManager.Peaceful.light
        case .happiness:
            return ColorManager.Happiness.light
        case .unhappy:
            return ColorManager.Unhappy.light
        }
    }
    
    // 根据日记情绪获取对应的次要颜色
    private func getEmotionSecondaryColor() -> Color {
        // 根据情绪类型返回对应的 secondary 颜色
        switch selectedEmotion {
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
    
    private func saveJournalWithContent(_ content: String) {
        // 显示 loading 状态
        isSaving = true
        
        Task {
            do {
                if isEditMode {
                    // 编辑模式：更新日记
                    guard let journalId = editJournalId else {
                        throw NetworkError.invalidResponse
                    }
                    
                    let keepImageIds = imageManager.getKeepImageIds()
                    let addImageData = imageManager.getAddImageData()
                    
                    let _ = try await JournalUpdateWithImagesService.shared.updateJournal(
                        journalId: journalId,
                        content: content,
                        emotion: selectedEmotion,
                        keepImageIds: keepImageIds,
                        addImageData: addImageData
                    )
                    
                    // 更新成功后刷新日记列表
                    await JournalListService.shared.syncJournals()
                    
                    await MainActor.run {
                        isSaving = false
                        // 发送日记更新通知
                        print("📢 发送日记更新通知: journal_\(journalId)")
                        NotificationCenter.default.post(name: .journalUpdated, object: journalId)
                        // 直接返回上一级，让详情页面重新加载数据
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
                        }
                    }
                } else {
                    // 创建模式：创建新日记
                    let imageData = imageManager.getAddImageData()
                    
                    let response = try await JournalUpdateWithImagesService.shared.createJournal(
                        content: content,
                        emotion: selectedEmotion,
                        imageData: imageData
                    )
                    
                    // 创建成功后刷新日记列表
                    await JournalListService.shared.syncJournals()
                    
                    await MainActor.run {
                        isSaving = false
                        // 发送日记更新通知
                        print("📢 发送日记更新通知: journal_\(response.journal_id)")
                        NotificationCenter.default.post(name: .journalUpdated, object: response.journal_id)
                        // 创建成功后清空导航栈，然后导航到新日记的详情页面
                        navigationPath = NavigationPath()
                        navigationPath.append(AppRoute.journalList)
                        navigationPath.append(AppRoute.journalDetail(id: response.journal_id))
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - 情绪选项视图
struct EmotionOptionView: View {
    let emotion: EmotionType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(emotion.iconName)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .opacity(isSelected ? 1.0 : 0.6)
                
                Text(emotion.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? emotion.color : .secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? emotion.color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? emotion.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    JournalEditView(initialEmotion: .happy, navigationPath: .constant(NavigationPath()))
} 

