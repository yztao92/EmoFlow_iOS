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
    
    // 富文本编辑状态
    @State private var isBold = false
    @State private var isItalic = false
    @State private var textAlignment: TextAlignment = .leading
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
    
    init(initialEmotion: EmotionType = .peaceful, navigationPath: Binding<NavigationPath>, isEditMode: Bool = false, editJournalId: Int? = nil, initialTitle: String = "", initialContent: String = "", initialHTMLContent: String = "") {
        self._selectedEmotion = State(initialValue: initialEmotion)
        self._title = State(initialValue: initialTitle)
        self._navigationPath = navigationPath
        
        // 处理初始内容：如果是HTML，转换为纯文本用于编辑
        let plainText = initialContent.isHTML ? initialContent.htmlToString() : initialContent
        self._content = State(initialValue: plainText)
        
        // 从HTML内容中解析富文本格式信息
        if !initialHTMLContent.isEmpty {
            let (parsedBold, parsedItalic, parsedAlignment) = parseHTMLFormat(initialHTMLContent)
            self._isBold = State(initialValue: parsedBold)
            self._isItalic = State(initialValue: parsedItalic)
            self._textAlignment = State(initialValue: parsedAlignment)
        }
        
        self.isEditMode = isEditMode
        self.editJournalId = editJournalId
    }
    
    // 新增：从 ChatRecord 创建编辑视图的初始化方法
    init(record: ChatRecord, navigationPath: Binding<NavigationPath>) {
        self._selectedEmotion = State(initialValue: record.emotion ?? .peaceful)
        self._title = State(initialValue: record.title ?? "")
        self._navigationPath = navigationPath
        
        // 处理初始内容：如果是HTML，转换为纯文本用于编辑
        let plainText = record.plainTextContent.isHTML ? record.plainTextContent.htmlToString() : record.plainTextContent
        self._content = State(initialValue: plainText)
        
        // 从HTML内容中解析富文本格式信息
        if !record.htmlContent.isEmpty {
            let (parsedBold, parsedItalic, parsedAlignment) = parseHTMLFormat(record.htmlContent)
            self._isBold = State(initialValue: parsedBold)
            self._isItalic = State(initialValue: parsedItalic)
            self._textAlignment = State(initialValue: parsedAlignment)
        }
        
        self.isEditMode = true
        self.editJournalId = record.backendId
    }
    
    // 从HTML内容中解析富文本格式
    private func parseHTMLFormat(_ htmlContent: String) -> (isBold: Bool, isItalic: Bool, alignment: TextAlignment) {
        var isBold = false
        var isItalic = false
        var alignment: TextAlignment = .leading // 默认左对齐
        
        // 检查是否包含粗体标签
        if htmlContent.contains("<strong>") || htmlContent.contains("<b>") {
            isBold = true
        }
        
        // 检查是否包含斜体标签
        if htmlContent.contains("<em>") || htmlContent.contains("<i>") {
            isItalic = true
        }
        
        // 检查对齐方式 - 只检查 <p> 标签的 class 属性
        if let pTagRange = htmlContent.range(of: "<p[^>]*>", options: .regularExpression) {
            let pTagStart = htmlContent.index(pTagRange.lowerBound, offsetBy: 2) // 跳过 "<p"
            let pTagEnd = htmlContent.index(pTagRange.upperBound, offsetBy: -1) // 跳过 ">"
            let pTagContent = String(htmlContent[pTagStart..<pTagEnd])
            
            // 检查 class 属性
            if pTagContent.contains("class=\"") {
                if let classStart = pTagContent.range(of: "class=\"") {
                    let classValueStart = pTagContent.index(classStart.upperBound, offsetBy: 0)
                    if let classEnd = pTagContent.range(of: "\"", range: classValueStart..<pTagContent.endIndex) {
                        let classValue = String(pTagContent[classValueStart..<classEnd.lowerBound])
                        
                        if classValue.contains("text-center") {
                            alignment = .center
                        } else if classValue.contains("text-right") {
                            alignment = .trailing
                        } else {
                            alignment = .leading
                        }
                    }
                }
            } else {
                // 没有 class 属性，默认为左对齐
                alignment = .leading
            }
        } else {
            // 没有找到 <p> 标签，默认为左对齐
            alignment = .leading
        }
        
        return (isBold, isItalic, alignment)
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
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .background(Color.clear)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // 富文本内容输入
                        VStack(alignment: .leading, spacing: 0) {
                            RichTextEditor(
                                text: $content,
                                isBold: $isBold,
                                isItalic: $isItalic,
                                textAlignment: $textAlignment,
                                placeholder: "写下你的心情..."
                            )
                            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 400)
                            
                            // 占位符（当内容为空时显示）
                            if content.isEmpty {
                                Text("写下你的心情...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
                
                // 富文本编辑工具栏 - 固定在底部，键盘上方
                if isTextEditorFocused {
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color(.systemGray4))
                        
                        HStack(spacing: 16) {
                            // 对齐方式按钮
                            Button(action: {
                                switch textAlignment {
                                case .leading:
                                    textAlignment = .center
                                case .center:
                                    textAlignment = .trailing
                                case .trailing:
                                    textAlignment = .leading
                                }
                            }) {
                                Image(systemName: getAlignmentIcon())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                            
                            // 粗体按钮
                            Button(action: {
                                isBold.toggle()
                            }) {
                                Image(systemName: isBold ? "bold.fill" : "bold")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isBold ? .blue : .primary)
                                    .frame(width: 32, height: 32)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                            
                            // 斜体按钮
                            Button(action: {
                                isItalic.toggle()
                            }) {
                                Image(systemName: isItalic ? "italic.fill" : "italic")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isItalic ? .blue : .primary)
                                    .frame(width: 32, height: 32)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            // 图片上传按钮（预留）
                            Button(action: {
                                // TODO: 实现图片上传功能
                            }) {
                                Image(systemName: "photo")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                    }
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
                .disabled(title.isEmpty || content.isEmpty || isSaving)
            }
        }
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TextEditorFocused"))) { _ in
            isTextEditorFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TextEditorUnfocused"))) { _ in
            isTextEditorFocused = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isTextEditorFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isTextEditorFocused = false
        }
    }
    
    // 获取对齐图标
    private func getAlignmentIcon() -> String {
        switch textAlignment {
        case .leading:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .trailing:
            return "text.alignright"
        }
    }
    
    private func saveJournal() {
        // 收起键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 显示 loading 状态
        isSaving = true
        
        Task {
            do {
                // 将纯文本转换为HTML格式保存，应用富文本格式
                let htmlContent = convertToHTML(content, isBold: isBold, isItalic: isItalic, alignment: textAlignment)
                
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
    
    // 将纯文本转换为HTML，应用富文本格式
    private func convertToHTML(_ text: String, isBold: Bool, isItalic: Bool, alignment: TextAlignment) -> String {
        var htmlText = text
        
        // 应用对齐方式（全局）
        let alignClass: String
        switch alignment {
        case .leading:
            alignClass = "text-left"
        case .center:
            alignClass = "text-center"
        case .trailing:
            alignClass = "text-right"
        }
        
        // 如果有富文本格式，应用格式
        if isBold || isItalic {
            var formattedText = htmlText
            
            // 应用粗体
            if isBold {
                formattedText = "<strong>\(formattedText)</strong>"
            }
            
            // 应用斜体
            if isItalic {
                formattedText = "<em>\(formattedText)</em>"
            }
            
            htmlText = formattedText
        }
        
        // 包装在段落标签中，应用对齐样式
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    font-size: 16px;
                    line-height: 1.5;
                    color: #000000;
                    margin: 0;
                    padding: 0;
                    background: transparent;
                }
                p {
                    margin: 0 0 12px 0;
                }
                strong {
                    font-weight: 600;
                }
                em {
                    font-style: italic;
                }
                .text-center {
                    text-align: center;
                }
                .text-left {
                    text-align: left;
                }
                .text-right {
                    text-align: right;
                }
            </style>
        </head>
        <body>
            <p class="\(alignClass)">\(htmlText)</p>
        </body>
        </html>
        """
        
        return htmlContent
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

