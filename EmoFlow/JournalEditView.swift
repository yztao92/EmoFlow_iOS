import SwiftUI

struct JournalEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedEmotion: EmotionType
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedTextAlignment: TextAlignment = .center
    @State private var isBold = false
    @State private var isItalic = false

    @State private var showImagePicker = false
    @State private var isTextEditorFocused = false
    
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
    
    init(initialEmotion: EmotionType = .peaceful, onJournalCreated: ((Int) -> Void)? = nil, isEditMode: Bool = false, editJournalId: Int? = nil, onJournalUpdated: ((Int) -> Void)? = nil, initialTitle: String = "", initialContent: String = "") {
        self._selectedEmotion = State(initialValue: initialEmotion)
        self._title = State(initialValue: initialTitle)
        self._content = State(initialValue: initialContent)
        self.onJournalCreated = onJournalCreated
        self.isEditMode = isEditMode
        self.editJournalId = editJournalId
        self.onJournalUpdated = onJournalUpdated
    }
    
    // 计算文本高度的辅助函数
    private func calculateTextHeight(_ text: String, fontSize: CGFloat = 16) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        let attributes = [NSAttributedString.Key.font: font]
        let size = CGSize(width: UIScreen.main.bounds.width - 64, height: .infinity) // 减去左右padding
        let boundingRect = text.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        return max(boundingRect.height + 40, 100) // 最小高度100，加上一些padding
    }
    

    
    // 获取对齐图标
    private func getAlignmentIcon() -> String {
        switch selectedTextAlignment {
        case .leading:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .trailing:
            return "text.alignright"
        }
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
                // 编辑区域 - 直接在页面内编辑
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                                                    // 情绪图标 - 页面居中显示，可点击切换
                            VStack(spacing: 16) {
                                Button(action: {
                                    // 点击切换情绪
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
                                        .frame(width: 80, height: 80)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .frame(maxWidth: .infinity, alignment: .center) // 确保整个VStack居中
                            .padding(.horizontal, 16)
                            .padding(.top, 40) // 增加顶部距离
                        
                                                    // 标题输入区域 - 直接在页面内编辑，居中
                            TextField("给这段心情起个标题...", text: $title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center) // 标题居中
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.clear) // 透明背景
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .center) // 确保标题居中
                        
                                                    // 内容输入区域 - 直接在页面内编辑，居中
                            ZStack(alignment: .bottomTrailing) {
                                TextEditor(text: $content)
                                    .font(.system(size: 16, weight: isBold ? .bold : .regular))
                                    .foregroundColor(.primary) // 移除颜色选择，使用默认颜色
                                    .multilineTextAlignment(selectedTextAlignment) // 动态对齐
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.clear) // 透明背景
                                    .frame(maxWidth: .infinity, alignment: .center) // 确保内容居中
                                    .frame(height: calculateTextHeight(content)) // 根据内容计算高度
                                    .scrollContentBackground(.hidden) // 移除TextEditor的默认背景
                                    .onTapGesture {
                                        isTextEditorFocused = true
                                    }
                                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                                        isTextEditorFocused = true
                                    }
                                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                                        isTextEditorFocused = false
                                    }
                                
                                // 日期显示在右下角
                                VStack(alignment: .trailing) {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text("\(getDayOfWeek()) \(getFormattedDate())")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .padding(.trailing, 20)
                                            .padding(.bottom, 8)
                                    }
                                }
                            }
                            
                            // 功能工具栏 - 只在输入框激活时显示
                            if isTextEditorFocused {
                                HStack(spacing: 16) {
                                    // 对齐方式按钮
                                    Button(action: {
                                        // 切换文本对齐方式
                                        switch selectedTextAlignment {
                                        case .leading:
                                            selectedTextAlignment = .center
                                        case .center:
                                            selectedTextAlignment = .trailing
                                        case .trailing:
                                            selectedTextAlignment = .leading
                                        }
                                    }) {
                                        Image(systemName: getAlignmentIcon())
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                            .frame(width: 32, height: 32)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    // 加粗按钮
                                    Button(action: {
                                        isBold.toggle()
                                    }) {
                                        Image(systemName: "bold")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(isBold ? .blue : .primary)
                                            .frame(width: 32, height: 32)
                                            .background(isBold ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    // 斜体按钮
                                    Button(action: {
                                        isItalic.toggle()
                                    }) {
                                        Image(systemName: "italic")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(isItalic ? .blue : .primary)
                                            .frame(width: 32, height: 32)
                                            .background(isItalic ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    // 图片上传按钮
                                    Button(action: {
                                        showImagePicker = true
                                    }) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                            .frame(width: 32, height: 32)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true) // 隐藏系统导航栏
        .overlay(
            // 自定义导航栏
            VStack {
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Spacer()
                    
                    Button("保存") {
                        saveJournal()
                    }
                    .foregroundColor(.blue)
                    .disabled(title.isEmpty || content.isEmpty || isSaving)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
            }
        )
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // 获取星期几
    private func getDayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
    
    // 获取格式化的日期
    private func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: Date())
    }
    
    // 根据日记情绪获取对应的背景颜色
    private func getEmotionBackgroundColor() -> Color? {
        // 从 EmotionData 中查找对应的背景颜色
        if let emotionData = EmotionData.emotions.first(where: { $0.assetName == selectedEmotion.iconName }) {
            return emotionData.backgroundColor
        }
        return nil
    }
    
    private func saveJournal() {
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
                        content: content,
                        emotion: selectedEmotion
                    )
                    
                    print("✅ 日记更新成功:")
                    print("日记ID: \(response.journal_id)")
                    print("标题: \(response.title)")
                    print("内容: \(response.content)")
                    print("情绪: \(response.emotion)")
                    
                    // 更新成功后刷新日记列表
                    await JournalListService.shared.syncJournals()
                    
                    await MainActor.run {
                        isSaving = false
                        // 调用编辑成功回调
                        onJournalUpdated?(response.journal_id)
                        dismiss()
                    }
                } else {
                    // 创建模式：创建新日记
                    let response = try await JournalCreateService.shared.createJournal(
                        title: title,
                        content: content,
                        emotion: selectedEmotion
                    )
                    
                    print("✅ 日记创建成功:")
                    print("日记ID: \(response.journal_id)")
                    print("标题: \(response.title)")
                    print("内容: \(response.content)")
                    print("情绪: \(response.emotion)")
                    
                    // 创建成功后刷新日记列表
                    await JournalListService.shared.syncJournals()
                    
                    await MainActor.run {
                        isSaving = false
                        // 调用回调，传递新创建的日记ID
                        onJournalCreated?(response.journal_id)
                        // 不调用 dismiss()，让回调处理导航
                    }
                }
            } catch {
                print("❌ 日记操作失败: \(error)")
                
                await MainActor.run {
                    isSaving = false
                    errorMessage = "保存失败，请检查网络连接后重试"
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
    JournalEditView(initialEmotion: .happy)
} 