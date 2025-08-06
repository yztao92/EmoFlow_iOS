import SwiftUI

struct JournalEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var title: String = ""
    @State private var attributedText: NSAttributedString = NSAttributedString(string: "")
    @State private var selectedEmotion: EmotionType
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // 富文本编辑状态
    @State private var textAlignment: NSTextAlignment = .center
    @State private var showRichTextToolbar = false
    
    // 富文本编辑器引用
    @State private var textViewRef: UITextView?
    
    // 创建成功后的回调
    var onJournalCreated: ((Int) -> Void)? = nil
    // 编辑成功后的回调
    var onJournalUpdated: ((Int) -> Void)? = nil
    // 是否为编辑模式
    var isEditMode: Bool = false
    // 编辑时的日记ID
    var editJournalId: Int? = nil
    
    // 情绪选项
    private let emotionOptions: [EmotionType] = [.angry, .sad, .unhappy, .peaceful, .happy, .happiness]
    
    init(initialEmotion: EmotionType = .peaceful, navigationPath: Binding<NavigationPath>, isEditMode: Bool = false, editJournalId: Int? = nil, initialTitle: String = "", initialContent: String = "", initialHTMLContent: String = "") {
        self._selectedEmotion = State(initialValue: initialEmotion)
        // 创建模式时，标题默认为情绪数据名称
        let defaultTitle = isEditMode ? initialTitle : initialEmotion.emotionDataName
        self._title = State(initialValue: defaultTitle)
        self._navigationPath = navigationPath
        
        // 处理初始内容：从HTML转换为富文本
        if !initialHTMLContent.isEmpty {
            self._attributedText = State(initialValue: RichTextHelper.htmlToAttributedString(initialHTMLContent))
        } else if !initialContent.isEmpty {
            self._attributedText = State(initialValue: NSAttributedString(string: initialContent))
        } else {
            // 创建空的富文本，默认居中对齐
            let emptyAttributedString = NSMutableAttributedString(string: "")
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            emptyAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: 0))
            self._attributedText = State(initialValue: emptyAttributedString)
        }
        
        // 默认居中对齐
        self._textAlignment = State(initialValue: .center)
        
        self.isEditMode = isEditMode
        self.editJournalId = editJournalId
    }
    
    // 新增：从 ChatRecord 创建编辑视图的初始化方法
    init(record: ChatRecord, navigationPath: Binding<NavigationPath>) {
        self._selectedEmotion = State(initialValue: record.emotion ?? .peaceful)
        self._title = State(initialValue: record.title ?? "")
        self._navigationPath = navigationPath
        
        // 处理初始内容：从HTML转换为富文本
        if !record.summary.isEmpty {
            self._attributedText = State(initialValue: RichTextHelper.htmlToAttributedString(record.summary))
        } else {
            self._attributedText = State(initialValue: NSAttributedString(string: ""))
        }
        
        // 默认居中对齐
        self._textAlignment = State(initialValue: .center)
        
        self.isEditMode = true
        self.editJournalId = record.backendId
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
                    VStack(spacing: 16) {
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
                        
                        // 富文本内容输入
                        VStack(alignment: .leading, spacing: 0) {
                            SimpleRichTextEditor(
                                attributedText: $attributedText,
                                placeholder: "写下你的心情...",
                                textViewRef: $textViewRef,
                                shouldFocus: !isEditMode
                            )
                            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 400)
                            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TextEditorFocused"))) { _ in
                                showRichTextToolbar = true
                            }
                            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TextEditorUnfocused"))) { _ in
                                showRichTextToolbar = false
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
                
                // 富文本编辑工具栏 - 固定在底部，键盘上方
                if showRichTextToolbar {
                    RichTextToolbar(
                        onBold: {
                            if let textView = textViewRef {
                                print("🔍 应用粗体")
                                RichTextHelper.applyBold(to: textView)
                            } else {
                                print("❌ textViewRef 为空")
                            }
                        },
                        onAlignment: {
                            // 循环切换对齐方式
                            switch textAlignment {
                            case .left:
                                textAlignment = .center
                            case .center:
                                textAlignment = .right
                            case .right:
                                textAlignment = .left
                            default:
                                textAlignment = .center
                            }
                            
                            if let textView = textViewRef {
                                print("🔍 应用对齐方式: \(textAlignment)")
                                print("🔍 当前 textView.textAlignment: \(textView.textAlignment)")
                                RichTextHelper.setAlignment(textAlignment, for: textView)
                                print("🔍 应用后 textView.textAlignment: \(textView.textAlignment)")
                            } else {
                                print("❌ textViewRef 为空")
                            }
                        },
                        currentAlignment: textAlignment
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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
                        .foregroundColor(.blue)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveJournal()
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
                .disabled(title.isEmpty || attributedText.string.isEmpty || isSaving)
            }
        }
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }


        .onAppear {
            // 创建模式时，延迟一下再聚焦到文本编辑器
            if !isEditMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showRichTextToolbar = true
                }
            }
        }
    }
    
    // 获取对齐图标
    private func getAlignmentIcon() -> String {
        switch textAlignment {
        case .left:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .right:
            return "text.alignright"
        case .justified:
            return "text.aligncenter"
        case .natural:
            return "text.aligncenter"
        @unknown default:
            return "text.aligncenter"
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
        
        // 直接获取富文本内容并保存
        let htmlContent = RichTextHelper.convertToHTML(attributedText)
        saveJournalWithHTML(htmlContent)
    }
    

    
    // 根据日记情绪获取对应的背景颜色
    private func getEmotionBackgroundColor() -> Color? {
        // 直接根据情绪类型返回对应的背景颜色
        switch selectedEmotion {
        case .happy:
            return Color.orange.opacity(0.3)
        case .sad:
            return Color.blue.opacity(0.3)
        case .angry:
            return Color.red.opacity(0.3)
        case .peaceful:
            return Color.green.opacity(0.3)
        case .happiness:
            return Color.yellow.opacity(0.3)
        case .unhappy:
            return Color.purple.opacity(0.3)
        }
    }
    
    private func saveJournalWithHTML(_ htmlContent: String) {
        // 显示 loading 状态
        isSaving = true
        
        Task {
            do {
                if isEditMode {
                    // 编辑模式：更新日记
                    guard let journalId = editJournalId else {
                        throw NetworkError.invalidResponse
                    }
                    
                    let response = try await JournalUpdateService.shared.updateJournal(
                        journalId: journalId,
                        title: title,
                        content: htmlContent,
                        emotion: selectedEmotion
                    )
                    
                    // 更新成功后刷新日记列表
                    await JournalListService.shared.syncJournals()
                    
                    await MainActor.run {
                        isSaving = false
                        // 清空导航栈，然后添加日记列表和详情页面
                        navigationPath = NavigationPath()
                        navigationPath.append(AppRoute.journalList)
                        navigationPath.append(AppRoute.journalDetail(id: response.journal_id))
                    }
                } else {
                    // 创建模式：创建新日记
                    let response = try await JournalCreateService.shared.createJournal(
                        title: title,
                        content: htmlContent,
                        emotion: selectedEmotion
                    )
                    
                    // 创建成功后刷新日记列表
                    await JournalListService.shared.syncJournals()
                    
                    await MainActor.run {
                        isSaving = false
                        // 清空导航栈，然后添加日记列表和详情页面
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

