import SwiftUI

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

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var inputHeight: CGFloat = 32

    // 添加缺失的变量定义
    @State private var sessionID: String = UUID().uuidString
    @State private var emotions: [EmotionType] = []
    
    // 添加键盘状态管理
    @State private var isKeyboardVisible = false
    @State private var keyboardHeight: CGFloat = 0

    @State private var showSavedAlert = false
    @State private var chatRecords: [ChatRecord] = RecordManager.loadAll()

    @State private var didLoadOpening = false  // 是否已加载开场消息
    @State private var didInsertInitialMessage = false // 新增，防止重复插入

    @State private var isSaving = false // 全局loading状态
    @State private var showToast = false // toast状态
    @State private var toastMessage = "" // toast消息内容
    @State private var didTimeout = false // 超时标志

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Color.clear.frame(height: 32)
                            
                            if messages.isEmpty && !isLoading {
                                // 空状态
                                VStack {
                                    Spacer()
                                    Text("暂无消息")
                                        .foregroundColor(.gray)
                                        .font(.body)
                                    Spacer()
                                }
                            } else {
                                // 显示聊天记录
                                ChatMessagesView(
                                    messages: messages,
                                    isLoading: isLoading,
                                    userBubbleColor: userBubbleColor,
                                    userEmojiImageName: userEmojiImageName,
                                    aiAvatarImageName: "AIicon"
                                )
                                
                                // 添加底部间距，确保键盘和内容之间有足够空间
                                Color.clear.frame(height: 60)
                                    .id("bottomSpacing")
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately) // 立即隐藏键盘
                    .scrollIndicators(.hidden) // 隐藏滚动指示器
                    // 使用两参数 onChange，避免单参废弃警告
                    .onChange(of: messages.count) { oldCount, newCount in
                        guard newCount > oldCount else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("bottomSpacing", anchor: .bottom)
                        }
                    }
                    // 监听loading状态变化，确保loading时滚动到底部
                    .onChange(of: isLoading) { oldValue, newValue in
                        print("🔍 ChatView - isLoading 变化: \(oldValue) -> \(newValue)")
                        
                        if newValue {
                            // 开始loading时，滚动到底部间距
                            print("✅ ChatView - 开始loading，滚动到底部间距")
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottomSpacing", anchor: .bottom)
                            }
                        }
                    }
                    // 确保总是滚动到底部间距
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottomSpacing", anchor: .bottom)
                            }
                        }
                    }
                }

                // 输入区域
                VStack(spacing: 0) {
                    // 分隔线
                    Divider()
                        .background(Color(.systemGray4))
                    
                    // 输入框和发送按钮
                    HStack(spacing: 12) {
                        // 输入框
                        TextField("输入消息...", text: $inputText, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGray6))
                            )
                            .frame(minHeight: 40, maxHeight: 100)
                            .onSubmit {
                                send()
                            }
                            // 进一步优化键盘处理
                            .onTapGesture {
                                // 使用更短的延迟，减少响应时间
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    // 确保输入框获得焦点
                                }
                            }
                            // 添加键盘优化
                            .textInputAutocapitalization(.sentences)
                            .disableAutocorrection(true)
                            .textContentType(.none)
                        
                        // 发送按钮
                        Button(action: send) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .ignoresSafeArea(.keyboard, edges: .bottom) // 优化键盘处理
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                // 键盘即将显示时的优化
                print("🔍 ChatView - 键盘即将显示")
                isKeyboardVisible = true
                
                // 获取键盘高度
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
                
                // 延迟滚动，避免卡顿
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        // 滚动到底部
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                // 键盘显示完成后的优化
                print("🔍 ChatView - 键盘显示完成")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                // 键盘即将隐藏时的优化
                print("🔍 ChatView - 键盘即将隐藏")
                isKeyboardVisible = false
                keyboardHeight = 0
            }
            .alert(isPresented: $showSavedAlert) {
                Alert(title: Text("已存档"),
                      message: Text("本次聊天内容已保存到记录页"),
                      dismissButton: .default(Text("好的")))
            }
            // 首次出现时自动插入初始消息并自动触发LLM回复
            .onAppear {
                print("[LOG] ChatView onAppear, initialMessage=\(initialMessage), didInsertInitialMessage=\(didInsertInitialMessage), emotions=\(emotions)")
                
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
                    print("[LOG] onAppear准备自动触发send(message: initialMessage)")
                    didInsertInitialMessage = true
                    send(message: initialMessage)
                }

            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 收起键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        // 生成日记
                        saveCurrentChat()
                    }) {
                        Text("生成日记")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            
            // 全局loading遮罩
            if isSaving {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
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
                        Text("生成日记失败，请重试")
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
    }

    // 无参数的 send 方法，用于按钮调用
    private func send() {
        send(message: nil)
    }

    // 支持外部传入message参数的send方法
    private func send(message: String? = nil) {
        let trimmed = (message ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        print("[LOG] send() called, message=\(String(describing: message)), trimmed=\(trimmed), isLoading=\(isLoading), emotions=\(emotions)")
        guard !trimmed.isEmpty else {
            print("[LOG] send() aborted: trimmed内容为空")
            return
        }
        if trimmed.lowercased().hasPrefix("user:") || trimmed.lowercased().hasPrefix("assistant:") {
            messages.append(.init(role: .assistant,
                                   content: "嘿，我们不用加 'user:' 或 'assistant:'，直接说出你的想法就好～"))
            inputText = ""
            print("[LOG] send() aborted: 前缀user:/assistant:")
            return
        }
        // 只在非initialMessage时append user消息
        let isInitial = (message != nil)
        if !isInitial {
        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        inputText = ""
        }
        isLoading = true
        print("[LOG] send() 发送给LLM, messages.count=\(messages.count), last=\(trimmed)")

        // 构造要发给LLM的消息数组
        let sendingMessages: [ChatMessageDTO]
        if isInitial {
            // 只发这一句话
            sendingMessages = [ChatMessageDTO(role: "user", content: trimmed)]
        } else {
            sendingMessages = messages.map { ChatMessageDTO(role: $0.role.rawValue, content: $0.content) }
        }

        Task {
            do {
                print("[LOG] ChatService.shared.sendMessage 开始, sessionID=\(sessionID)")
                print("[LOG] 传递给ChatService的参数:")
                print("   Session ID: \(sessionID)")
                print("   Emotions: \(emotions)")
                print("   Messages Count: \(sendingMessages.count)")
                for (index, msg) in sendingMessages.enumerated() {
                    print("   Message \(index + 1): role=\(msg.role), content=\(msg.content)")
                }
                
                let (answer, references) = try await ChatService.shared.sendMessage(
                    sessionID: sessionID,
                    emotions: emotions,
                    messages: sendingMessages
                )
                print("[LOG] ChatService.shared.sendMessage 成功, answer=\(answer)")
                messages.append(.init(role: .assistant, content: answer, references: references))
            } catch {
                print("[LOG] ChatService.shared.sendMessage 失败, error=\(error)")
                messages.append(.init(role: .assistant, content: "出错了，请重试"))
            }
            isLoading = false
            print("🔍 ChatView - send() 方法中 isLoading 设置为 false")
        }
    }

    private func saveCurrentChat() {
        guard !messages.isEmpty else { return }
        let emotion = emotions.first ?? .happy
        DispatchQueue.main.async { self.isSaving = true; self.didTimeout = false }
        // 启动超时定时器
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if self.isSaving {
                self.didTimeout = true
                DispatchQueue.main.async {
                    self.isSaving = false
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
                let (journal, title, journalId) = try await JournalService.shared.generateJournal(
                    emotions: [emotion],
                    messages: messages.map { ChatMessageDTO(role: $0.role.rawValue, content: $0.content) }
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
                            
                            print("✅ ChatView - 调用导航，backendId: \(backendId)")
                            // 清空导航栈，然后添加日记列表和详情页面
                            navigationPath = NavigationPath()
                            navigationPath.append(AppRoute.journalList)
                            navigationPath.append(AppRoute.journalDetail(id: backendId))
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
                                if let backendId = latestJournal.backendId {
                                    print("✅ ChatView - 调用导航，backendId: \(backendId)")
                                    // 清空导航栈，然后添加日记列表和详情页面
                                    navigationPath = NavigationPath()
                                    navigationPath.append(AppRoute.journalList)
                                    navigationPath.append(AppRoute.journalDetail(id: backendId))
                                } else {
                                    print("❌ ChatView - 最新日记没有 backendId")
                                }
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
                let fallbackSummary = messages.first?.content ?? "新会话"
                let now = Date()
                let fallbackRecord = ChatRecord(id: UUID(), date: now, messages: messages, summary: fallbackSummary, emotion: emotion, title: "今日心情")
                chatRecords.append(fallbackRecord)
                RecordManager.saveAll(chatRecords)
                DispatchQueue.main.async {
                    showToast = true
                    isSaving = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
    }
}

