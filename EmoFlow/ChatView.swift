import SwiftUI

struct ChatView: View {
    let emotions: [EmotionType]

    /// 用户气泡色：取第一个情绪的颜色
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
                    // 顶部留白，避免被 sheet 把手或导航栏顶住
                    Color.clear
                        .frame(height: 32)

                    // 真正的消息列表
                    ChatMessagesView(
                        messages: messages,
                        isLoading: isLoading,
                        userBubbleColor: userBubbleColor
                    )
                }
                // iOS 17+ 零参 onChange 版本
                .onChange(of: messages.count) {
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
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
