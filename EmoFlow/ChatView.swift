import SwiftUI

struct ChatView: View {
    @Binding var emotions: [EmotionType]
    @Binding var selectedTab: Int      // 当前选中 Tab 索引
    var initialMessage: String         // 新增：初始消息
    var sessionID: String
    @Binding var selectedRecord: ChatRecord?

    // 用户头像表情
    private var userEmojiImageName: String {
        guard let emo = emotions.first else { return "Happy" }
        switch emo {
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
    @FocusState private var isInputFocused: Bool

    @State private var showSavedAlert = false
    @State private var chatRecords: [ChatRecord] = RecordManager.loadAll()

    @State private var didLoadOpening = false  // 是否已加载开场消息
    @State private var didInsertInitialMessage = false // 新增，防止重复插入
    @State private var inputHeight: CGFloat = 36

    @State private var isSaving = false // 全局loading状态
    @State private var showToast = false // toast状态
    @State private var didTimeout = false // 超时标志

    var body: some View {
        ZStack {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear.frame(height: 32)
                        if isLoading {
                            HStack(alignment: .bottom, spacing: 8) {
                                Image("AIicon")
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                TextBubbleView(
                                    text: "AI 正在思考…",
                                    color: Color.gray.opacity(0.18),
                                    alignment: .leading,
                                    isLoading: true
                                )
                                Spacer()
                            }
                        } else if messages.isEmpty {
                            VStack {
                                Spacer()
                                Text("暂无消息")
                                    .foregroundColor(.gray)
                                    .font(.body)
                                Spacer()
                            }
                        } else {
                    ChatMessagesView(
                        messages: messages,
                        isLoading: isLoading,
                        userBubbleColor: userBubbleColor,
                        userEmojiImageName: userEmojiImageName,
                        aiAvatarImageName: "AIicon"
                    )
                        }
                }
                // 使用两参数 onChange，避免单参废弃警告
                .onChange(of: messages.count) { oldCount, newCount in
                    guard newCount > oldCount,
                          let lastId = messages.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
                    // 点击聊天区域时隐藏键盘但保持焦点
                    .onTapGesture {
                        if isInputFocused {
                            // 隐藏键盘但保持焦点状态
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
            }

            Divider()

            HStack(spacing: 8) {
                    // 可预留左侧icon
                    // Image(systemName: "mic.fill").foregroundColor(.gray)
                    ZStack(alignment: .leading) {
                        if inputText.isEmpty {
                            Text("说点什么...")
                                .foregroundColor(Color.gray.opacity(0.7))
                                .padding(.horizontal, 12)
                        }
                        AutoSizingTextEditor(text: $inputText, dynamicHeight: $inputHeight)
                            .frame(height: max(inputHeight, 38))
                            .padding(.horizontal, 8)
                            .foregroundColor(.primary)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(
                                        UIColor { trait in
                                            trait.userInterfaceStyle == .dark ? UIColor(white: 0.18, alpha: 0.95) : UIColor(white: 0.97, alpha: 0.95)
                                        }
                                    ))
                            )
                    }
                    .frame(height: 38)
                    Button(action: { send() }) {
                        Text("发送")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 56, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill((inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading) ? Color.gray.opacity(0.2) : Color.accentColor)
                            )
                            .foregroundColor((inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading) ? .gray : .white)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    Color.clear
                )
            }

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
        .alert(isPresented: $showSavedAlert) {
            Alert(title: Text("已存档"),
                  message: Text("本次聊天内容已保存到记录页"),
                  dismissButton: .default(Text("好的")))
        }
        // 首次出现时自动插入初始消息并自动触发LLM回复
        .onAppear {
            print("[LOG] ChatView onAppear, initialMessage=\(initialMessage), didInsertInitialMessage=\(didInsertInitialMessage), emotions=\(emotions)")
            if !initialMessage.isEmpty && !didInsertInitialMessage {
                isLoading = true // 先设置为true，保证UI立即显示loading
                print("[LOG] onAppear准备自动触发send(message: initialMessage)")
                didInsertInitialMessage = true
                send(message: initialMessage)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveCurrentChat) {
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
        isInputFocused = false
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
            // AI回复完成后重新聚焦到输入框
            DispatchQueue.main.async {
                isInputFocused = true
            }
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
                let (journal, title) = try await JournalService.shared.generateJournal(
                    emotions: [emotion],
                    messages: messages.map { ChatMessageDTO(role: $0.role.rawValue, content: $0.content) }
                )
                if didTimeout { return } // 超时后不再处理
                print("📓 AI 生成的心情日记：\n\(journal)")
                let newRecord = ChatRecord(id: UUID(), date: Date(), messages: messages, summary: journal, emotion: emotion, title: title)
                chatRecords.append(newRecord)
                RecordManager.saveAll(chatRecords)
                DispatchQueue.main.async {
                    if !didTimeout {
                        selectedTab = 1
                        selectedRecord = newRecord // 跳转到详情页
                        isSaving = false
                    }
                }
            } catch {
                if didTimeout { return }
                print("❌ 生成心情日记失败: \(error)")
                let fallbackSummary = messages.first?.content ?? "新会话"
                let fallbackRecord = ChatRecord(id: UUID(), date: Date(), messages: messages, summary: fallbackSummary, emotion: emotion, title: "今日心情")
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

