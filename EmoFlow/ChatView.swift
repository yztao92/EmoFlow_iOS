import SwiftUI

struct ChatView: View {
    @Binding var emotions: [EmotionType]
    @Binding var selectedTab: Int      // 当前选中 Tab 索引
    @Binding var showChatSheet: Bool   // 控制弹窗显示

    // 用户头像表情
    private var userEmojiImageName: String {
        guard let emo = emotions.first else { return "EmojiHappy" }
        switch emo {
        case .happy: return "EmojiHappy"
        case .tired: return "EmojiTired"
        case .sad:   return "EmojiSad"
        case .angry: return "EmojiAngry"
        }
    }
    // 用户消息气泡颜色
    private var userBubbleColor: Color {
        emotions.first?.color ?? .blue
    }

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool

    @State private var showSavedAlert = false
    @State private var chatRecords: [ChatRecord] = RecordManager.loadAll()

    @State private var didLoadOpening = false  // 是否已加载开场消息

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear.frame(height: 32)
                    ChatMessagesView(
                        messages: messages,
                        isLoading: isLoading,
                        userBubbleColor: userBubbleColor,
                        userEmojiImageName: userEmojiImageName,
                        aiAvatarImageName: "AIicon"
                    )
                }
                // 使用两参数 onChange，避免单参废弃警告
                .onChange(of: messages.count) { oldCount, newCount in
                    guard newCount > oldCount,
                          let lastId = messages.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                Button(action: saveCurrentChat) {
                    Image(systemName: "archivebox").foregroundColor(.blue)
                }
                TextField("说点什么...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                Button("发送") { send() }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("情绪对话")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showSavedAlert) {
            Alert(title: Text("已存档"),
                  message: Text("本次聊天内容已保存到记录页"),
                  dismissButton: .default(Text("好的")))
        }
        // 首次出现和 émotion 变化时加载开场提示
        .onAppear { maybeLoadOpening() }
        .onChange(of: emotions) { _, _ in maybeLoadOpening() }
    }

    private func maybeLoadOpening() {
        guard !didLoadOpening else { return }
        didLoadOpening = true
        let mood = emotions.first ?? .happy
        let moodText: String
        switch mood {
        case .happy:
            moodText = "听起来今天心情不错～有什么有趣的事想记录一下吗？"
        case .tired:
            moodText = "感觉有点疲惫呢～要不要聊聊今天的压力？"
        case .sad:
            moodText = "哎呀，是不是遇到什么不开心的事了？我在呢～"
        case .angry:
            moodText = "好像有点生气了？我可以陪你说说看～"
        }
        messages.append(.init(role: .assistant, content: moodText))
    }

    private func send() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if trimmed.lowercased().hasPrefix("user:") || trimmed.lowercased().hasPrefix("assistant:") {
            messages.append(.init(role: .assistant,
                                   content: "嘿，我们不用加 'user:' 或 'assistant:'，直接说出你的想法就好～"))
            inputText = ""
            return
        }
        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        isInputFocused = false

        Task {
            do {
                let (answer, references) = try await ChatService.shared.sendMessage(
                    emotions: emotions,
                    messages: messages.map { ChatMessageDTO(role: $0.role.rawValue, content: $0.content) }
                )
                messages.append(.init(role: .assistant, content: answer, references: references))
            } catch {
                messages.append(.init(role: .assistant, content: "出错了，请重试"))
            }
            isLoading = false
        }
    }

    private func saveCurrentChat() {
        guard !messages.isEmpty else { return }
        let emotion = emotions.first ?? .happy
        Task {
            do {
                let journal = try await JournalService.shared.generateJournal(
                    emotions: [emotion],
                    messages: messages.map { ChatMessageDTO(role: $0.role.rawValue, content: $0.content) }
                )
                print("📓 AI 生成的心情日记：\n\(journal)")
                let newRecord = ChatRecord(id: UUID(), date: Date(), messages: messages, summary: journal, emotion: emotion)
                chatRecords.append(newRecord)
                RecordManager.saveAll(chatRecords)
            } catch {
                print("❌ 生成心情日记失败: \(error)")
                let fallbackSummary = messages.first?.content ?? "新会话"
                let fallbackRecord = ChatRecord(id: UUID(), date: Date(), messages: messages, summary: fallbackSummary, emotion: emotion)
                chatRecords.append(fallbackRecord)
                RecordManager.saveAll(chatRecords)
            }
            showChatSheet = false
            selectedTab = 1
        }
    }
}
