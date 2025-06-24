import SwiftUI

struct ChatView: View {
    let emotions: [EmotionType]

    // 用户头像：Asset 里的图片名
    private var userEmojiImageName: String {
        guard let emo = emotions.first else { return "EmojiHappy" }
        switch emo {
        case .happy: return "EmojiHappy"
        case .tired: return "EmojiTired"
        case .sad:   return "EmojiSad"
        case .angry: return "EmojiAngry"
        }
    }

    // 用户气泡色：取第一个情绪的颜色
    private var userBubbleColor: Color {
        emotions.first?.color ?? .blue
    }

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool

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
                        aiAvatarImageName: "AIicon" // 这里是 AI 头像 Asset 名称
                    )
                }
                .onChange(of: messages.count) {
                    guard let lastId = messages.last?.id else { return }
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack {
                TextField("说点什么...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)

                Button("发送") {
                    send()
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("情绪对话")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 多次尝试聚焦，兼容真机 sheet 场景
            for i in 1...5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    isInputFocused = true
                }
            }
            Task { await loadOpeningMessage() }
        }
    }

    private func loadOpeningMessage() async {
        isLoading = true
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
        messages.append(ChatMessage(role: .assistant, content: moodText))
        isLoading = false
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
                    messages: messages.map {
                        ChatMessageDTO(role: $0.role.rawValue, content: $0.content)
                    }
                )
                messages.append(.init(role: .assistant, content: answer, references: references))
            } catch {
                messages.append(.init(role: .assistant, content: "出错了，请重试"))
            }
            isLoading = false
        }
    }
}
