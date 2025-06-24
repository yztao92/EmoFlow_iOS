import SwiftUI

struct ChatMessagesView: View {
    let messages: [ChatMessage]
    let isLoading: Bool
    let userBubbleColor: Color
    let userEmojiImageName: String
    let aiAvatarImageName: String

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(messages) { msg in
                HStack(alignment: .bottom, spacing: 8) {
                    if msg.role == .assistant {
                        Image(aiAvatarImageName)
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        TextBubbleView(
                            text: msg.content,
                            color: Color.gray.opacity(0.18),
                            alignment: .leading
                        )
                        Spacer()
                    } else {
                        Spacer()
                        TextBubbleView(
                            text: msg.content,
                            color: userBubbleColor.opacity(0.95),
                            alignment: .trailing
                        )
                        Image(userEmojiImageName)
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            if isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("AI 正在思考…")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12) // <<< 推荐 12 或 16
    }
}

/// 微信风格气泡
struct TextBubbleView: View {
    let text: String
    let color: Color
    let alignment: Alignment

    var body: some View {
        Text(text)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(color)
            .cornerRadius(12)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: alignment)
    }
}
