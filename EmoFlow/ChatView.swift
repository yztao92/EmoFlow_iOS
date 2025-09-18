import SwiftUI

// 定义自动发送图片的通知
extension Notification.Name {
    static let autoSendImage = Notification.Name("autoSendImage")
}

struct ChatView: View {
    let emotion: EmotionType
    let initialMessage: String
    @Binding var navigationPath: NavigationPath

    // 用户头像表情
    private var userEmojiImageName: String {
        switch emotion {
        case .happy: return "Happy"
        case .unhappy: return "Unhappy"
        case .sad: return "Sad"
        case .angry: return "Angry"
        case .peaceful: return "Peaceful"
        case .happiness: return "Happiness"
        }
    }
    // 用户消息气泡颜色统一为微信风格灰色
    private let userBubbleColor: Color = Color(UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1))
    
    // 根据情绪获取背景颜色
    private var emotionBackgroundColor: Color {
        switch emotion {
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
    
    // 根据情绪获取次要颜色
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

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var inputHeight: CGFloat = 32
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showImageSourceActionSheet = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showFullScreenImage = false
    @State private var fullScreenImage: UIImage? = nil

    // 添加缺失的变量定义
    @State private var sessionID: String = ""
    @State private var emotions: [EmotionType] = []
    
    // 优化键盘状态管理
    @State private var isKeyboardVisible = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var shouldScrollToBottom = false // 新增：控制是否需要滚动到底部

    @State private var showSavedAlert = false
    @State private var chatRecords: [ChatRecord] = RecordManager.loadAll()

    @State private var didLoadOpening = false  // 是否已加载开场消息
    @State private var didInsertInitialMessage = false // 新增，防止重复插入

    @State private var isSaving = false // 全局loading状态
    @State private var showToast = false // toast状态
    @State private var toastMessage = "" // toast消息内容
    @State private var didTimeout = false // 超时标志
    @FocusState private var isInputFocused: Bool
    @State private var typingText: String? = nil
    
    // AI聊天loading状态管理
    @State private var isLoadingLongTime = false // 是否加载超过10秒
    @State private var loadingStartTime: Date? = nil // 开始加载的时间

    var body: some View {
        ZStack {
            // 背景色
            emotionBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 聊天内容区域
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // 顶部间距
                            Color.clear.frame(height: 16)
                            
                            if messages.isEmpty && !isLoading {
                                // 空状态 - ChatGPT风格
                                VStack(spacing: 20) {
                                    Spacer()
                                    Image("AIicon")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.gray)
                                    Text("EmoFlow")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            } else {
                                // 显示聊天记录
                                ChatMessagesView(
                                    messages: messages,
                                    isLoading: isLoading,
                                    isLoadingLongTime: isLoadingLongTime,
                                    userBubbleColor: userBubbleColor,
                                    userEmojiImageName: userEmojiImageName,
                                    aiAvatarImageName: "AIicon",
                                    onImageTap: { image in
                                        print("🔍 在ChatView中处理图片点击")
                                        fullScreenImage = image
                                        showFullScreenImage = true
                                    }
                                )
                                
                                // 底部间距
                                Color.clear.frame(height: 20)
                                    .id("bottomSpacing")
                            }
                        }
                        .id("messages")
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .scrollIndicators(.hidden)
                    // 统一滚动动画时长和逻辑
                    .onChange(of: shouldScrollToBottom) { oldValue, newValue in
                        if newValue {
                            // 使用统一的滚动逻辑
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("bottomSpacing", anchor: .bottom)
                                }
                                // 重置滚动标志
                                shouldScrollToBottom = false
                            }
                        }
                    }
                    .onChange(of: messages.count) { oldCount, newCount in
                        guard newCount > oldCount else { return }
                        // 新消息时滚动到底部
                        shouldScrollToBottom = true
                    }
                    .onChange(of: isLoading) { oldValue, newValue in
                        if newValue {
                            // 加载状态时滚动到底部
                            shouldScrollToBottom = true
                        }
                    }
                }

                // 输入区域 - 键盘适配
                VStack(spacing: 0) {
                    Divider()
                    
                    // 选中的图片预览（只在非自动发送模式下显示）
                    if let selectedImage = selectedImage, !isLoading {
                        HStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 100)
                                .cornerRadius(8)
                            
                            Button(action: {
                                self.selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }
                    
                    HStack(spacing: 8) {
                        // 图片选择按钮
                        Button(action: {
                            showImageSourceActionSheet = true
                        }) {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(emotionSecondaryColor)
                        }
                        
                        TextField("消息", text: $inputText, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(ColorManager.inputFieldColor)
                            .cornerRadius(8)
                            .focused($isInputFocused)
                        
                        Button(action: send) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor((inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil) ? .gray : emotionSecondaryColor)
                        }
                        .disabled((inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil) || isLoading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .background(emotionBackgroundColor)
                .padding(.bottom, isKeyboardVisible ? 0 : 0)
            }
            .animation(.easeOut(duration: 0.25), value: isKeyboardVisible) // 统一动画时长
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                // 键盘即将显示时，标记需要滚动
                shouldScrollToBottom = true
                withAnimation(.easeOut(duration: 0.25)) {
                    isKeyboardVisible = true
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                // 键盘显示完成，确保滚动到底部
                shouldScrollToBottom = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    isKeyboardVisible = false
                    keyboardHeight = 0
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .autoSendImage)) { _ in
                // 自动发送图片
                if selectedImage != nil {
                    print("[LOG] 收到自动发送图片通知")
                    send()
                }
            }
            .alert(isPresented: $showSavedAlert) {
                Alert(title: Text("已存档"),
                      message: Text("本次聊天内容已保存到记录页"),
                      dismissButton: .default(Text("好的")))
            }
            // 首次出现时自动插入初始消息并自动触发LLM回复
            .onAppear {
                print("[LOG] ChatView onAppear")
                
                // 初始化 emotions 数组
                if emotions.isEmpty {
                    emotions = [emotion]
                }
                
                // 性能监控
                print("🔍 ChatView - 性能监控开始")
                print("   messages.count: \(messages.count)")
                print("   isLoading: \(isLoading)")
                print("   isKeyboardVisible: \(isKeyboardVisible)")
                
                if !initialMessage.isEmpty && !didInsertInitialMessage {
                    isLoading = true // 先设置为true，保证UI立即显示loading
                    print("[LOG] 自动触发初始消息")
                    didInsertInitialMessage = true
                    send(message: initialMessage)
                }
                
                // 延迟一下再聚焦到输入框，确保UI已经加载完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFocused = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
                        }
                    }) {
                        HStack(spacing: 0) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer().frame(width: 16)
                            
                            Image(systemName: "star.fill")
                                .font(.system(size: 12, weight: .medium))
                            
                            Spacer().frame(width: 8)
                            
                            Text("\(UserDefaults.standard.integer(forKey: "heartCount"))")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .foregroundColor(emotionSecondaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 收起键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        // 生成日记
                        saveCurrentChat()
                    }) {
                        Text("AI 日记")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(emotionSecondaryColor)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                print("🎨 ChatView 背景颜色: \(emotionBackgroundColor)")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: imagePickerSourceType, autoSend: true)
            }
            .actionSheet(isPresented: $showImageSourceActionSheet) {
                ActionSheet(
                    title: Text("选择图片"),
                    buttons: [
                        .default(Text("拍照")) {
                            imagePickerSourceType = .camera
                            showImagePicker = true
                        },
                        .default(Text("从相册选择")) {
                            imagePickerSourceType = .photoLibrary
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            
            // 全局loading遮罩
            if isSaving {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: emotionSecondaryColor))
                        .scaleEffect(1.4)
                    Text("正在生成日记…")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemGray5).opacity(0.85))
                )
            }
            
            // toast
            if showToast {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(toastMessage.isEmpty ? "操作失败，请重试" : toastMessage)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(18)
                        Spacer()
                    }
                    .padding(.bottom, 60)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showToast)
            }
        }
        .onAppear {
            // 初始化会话ID（如果还没有的话）
            if sessionID.isEmpty {
                sessionID = UUID().uuidString
                print("🔍 ChatView - 初始化会话ID: \(sessionID)")
            }
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let fullScreenImage = fullScreenImage {
                FullScreenImageView(image: fullScreenImage, isPresented: $showFullScreenImage)
                    .onAppear {
                        print("🔍 显示全屏图片查看器")
                    }
            } else {
                Text("图片加载失败")
                    .foregroundColor(.white)
                    .background(Color.black)
                    .onAppear {
                        print("🔍 fullScreenImage 为 nil")
                    }
            }
        }
    }

    // 无参数的 send 方法，用于按钮调用
    private func send() {
        send(message: nil)
    }

    // 支持外部传入message参数的send方法
    private func send(message: String? = nil) {
        let trimmed = (message ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        print("[LOG] send() called")
        guard !trimmed.isEmpty || selectedImage != nil else {
            print("[LOG] send() aborted: 内容和图片都为空")
            return
        }
        if trimmed.lowercased().hasPrefix("user:") || trimmed.lowercased().hasPrefix("assistant:") {
            messages.append(.init(role: .assistant,
                                   content: "嘿，我们不用加 'user:' 或 'assistant:'，直接说出你的想法就好～"))
            inputText = ""
            print("[LOG] send() aborted: 前缀user:/assistant:")
            return
        }
        
        // 在发送消息前先检查心心数量
        let currentHeartCount = UserDefaults.standard.integer(forKey: "heartCount")
        guard currentHeartCount >= 2 else {
            // 心心数量不足，直接显示toast并拦截
            toastMessage = "星星数量不足，聊天需要至少2个心心"
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showToast = false
            }
            print("[LOG] send() aborted: 心心数量不足，当前: \(currentHeartCount)，需要: 2")
            return
        }
        
        // 心心数量足够，继续发送消息
        // 始终添加用户消息到聊天界面显示
        let isInitial = (message != nil)
        
        // 先保存图片数据，避免在清空selectedImage后丢失
        // 压缩图片以减少文件大小，避免上传失败
        let imageDataForSending = selectedImage?.jpegData(compressionQuality: 0.5)
        
        let userMessage = ChatMessage(role: .user, content: trimmed, imageData: imageDataForSending)
        messages.append(userMessage)
        if !isInitial {
            inputText = ""
            selectedImage = nil
        }
        isLoading = true
        isLoadingLongTime = false
        loadingStartTime = Date()
        print("[LOG] 发送给LLM")
        print("[LOG] 图片数据大小: \(imageDataForSending?.count ?? 0) bytes")
        
        // 启动10秒计时器
        startLoadingTimer()

        Task {
            do {
                print("[LOG] ChatService 开始发送")
                print("🔍 ChatView - 发送聊天消息，使用会话ID: \(sessionID)")
                
                let answer = try await ChatService.shared.sendMessage(
                    sessionID: sessionID,
                    userMessage: trimmed,
                    emotion: emotions.first,
                    imageData: imageDataForSending
                )
                print("[LOG] ChatService 发送成功")
                // 原来是直接append完整内容
                // messages.append(.init(role: .assistant, content: answer, references: []))
                // 现在改为先插入空assistant消息，再逐字显示
                let newMsg = ChatMessage(role: .assistant, content: "", references: [])
                messages.append(newMsg)
                startTypewriterEffect(fullText: answer)
            } catch {
                print("[LOG] ChatService 发送失败: \(error)")
                print("[LOG] 错误类型: \(type(of: error))")
                print("[LOG] 错误描述: \(error.localizedDescription)")
                
                // 其他错误，显示通用错误消息
                messages.append(.init(role: .assistant, content: "出错了，请重试"))
            }
            isLoading = false
            isLoadingLongTime = false
            loadingStartTime = nil
            print("🔍 ChatView - send() 方法中 isLoading 设置为 false")
        }
    }

    // 启动loading计时器
    private func startLoadingTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // 如果还在loading状态，说明超过5秒了
            if self.isLoading {
                self.isLoadingLongTime = true
                print("🔍 ChatView - 加载超过5秒，显示'互联网检索中'")
            }
        }
    }
    
    private func saveCurrentChat() {
        guard !messages.isEmpty else { return }
        
        // 在生成日记前先检查心心数量
        let currentHeartCount = UserDefaults.standard.integer(forKey: "heartCount")
        guard currentHeartCount >= 4 else {
            // 心心数量不足，直接显示toast并拦截
            toastMessage = "星星数量不足，生成日记需要至少4个心心"
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showToast = false
            }
            print("[LOG] saveCurrentChat() aborted: 心心数量不足，当前: \(currentHeartCount)，需要: 4")
            return
        }
        
        let emotion = emotions.first ?? .happy
        DispatchQueue.main.async { self.isSaving = true; self.didTimeout = false }
        // 启动超时定时器
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if self.isSaving {
                self.didTimeout = true
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.toastMessage = "生成日记超时，请重试"
                    self.showToast = true
                }
                // toast自动消失
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showToast = false
                }
            }
        }
        Task {
            do {
                print("🔍 ChatView - 准备生成日记，使用会话ID: \(sessionID)")
                let (journal, title, journalId) = try await JournalService.shared.generateJournal(
                    emotion: emotion,
                    sessionID: sessionID
                )
                if didTimeout { return } // 超时后不再处理
                print("📓 AI 生成的心情日记：\n\(journal)")
                print("🔍 ChatView - 生成日记返回的ID: \(journalId ?? -1)")
                
                if let backendId = journalId {
                    print("✅ ChatView - 后端已创建日记，ID: \(backendId)")
                    
                    // 创建本地记录
                    let now = Date()
                    let newRecord = ChatRecord(
                        id: UUID(),
                        backendId: backendId,
                        date: now,
                        messages: messages,
                        summary: journal,
                        emotion: emotion,
                        title: title
                    )
                    chatRecords.append(newRecord)
                    RecordManager.saveAll(chatRecords)
                    
                    DispatchQueue.main.async {
                        if !didTimeout {
                            isSaving = false
                            // 自己处理导航：跳转到日记详情
                            print("🔍 ChatView - 生成日记成功，准备跳转")
                            print("   日记ID: \(backendId)")
                            
                            print("✅ ChatView - 调用导航，跳转到日记列表")
                            // 清空导航栈，然后跳转到日记列表
                            navigationPath = NavigationPath()
                            navigationPath.append(AppRoute.journalList)
                        }
                    }
                } else {
                    print("❌ ChatView - 后端未返回日记ID，尝试获取最新日记")
                    
                    // 获取最新的日记列表，找到刚创建的日记
                    let latestJournals = try await JournalListService.shared.fetchJournals(limit: 10, offset: 0)
                    
                    if let latestJournal = latestJournals.first {
                        print("✅ ChatView - 找到最新日记，ID: \(latestJournal.backendId ?? -1)")
                        
                        // 更新本地记录
                        chatRecords.append(latestJournal)
                        RecordManager.saveAll(chatRecords)
                        
                        DispatchQueue.main.async {
                            if !didTimeout {
                                isSaving = false
                                // 跳转到最新日记的详情页
                                print("✅ ChatView - 调用导航，跳转到日记列表")
                                // 清空导航栈，然后跳转到日记列表
                                navigationPath = NavigationPath()
                                navigationPath.append(AppRoute.journalList)
                            }
                        }
                    } else {
                        print("❌ ChatView - 未找到最新日记")
                        DispatchQueue.main.async {
                            isSaving = false
                        }
                    }
                }
            } catch {
                if didTimeout { return }
                print("❌ 生成心情日记失败: \(error)")
                
                // 其他错误，创建本地记录并显示通用错误
                let fallbackSummary = messages.first?.content ?? "新会话"
                let now = Date()
                let fallbackRecord = ChatRecord(id: UUID(), date: now, messages: messages, summary: fallbackSummary, emotion: emotion, title: "今日心情")
                chatRecords.append(fallbackRecord)
                RecordManager.saveAll(chatRecords)
                DispatchQueue.main.async {
                    toastMessage = "生成日记失败，请重试"
                    showToast = true
                    isSaving = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
    }

    private func startTypewriterEffect(fullText: String) {
        typingText = ""
        let chars = Array(fullText)
        Task {
            for i in 0..<chars.count {
                await MainActor.run {
                    typingText = String(chars[0...i])
                    // 实时更新最后一条assistant消息内容
                    if let lastIdx = messages.lastIndex(where: { $0.role == .assistant }) {
                        let oldMsg = messages[lastIdx]
                        messages[lastIdx] = ChatMessage(
                            id: oldMsg.id,
                            role: oldMsg.role,
                            content: typingText!,
                            references: oldMsg.references
                        )
                    }
                }
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms/字
            }
            await MainActor.run {
                typingText = nil // 结束打字机
            }
        }
    }
}

