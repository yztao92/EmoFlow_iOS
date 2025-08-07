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
                            color: ColorManager.inputFieldColor,
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
                HStack(alignment: .bottom, spacing: 8) {
                    Image(aiAvatarImageName)
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
    var isLoading: Bool = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        Text(text)
        }
            .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
                .shadow(color: (colorScheme == .dark ? Color.black.opacity(0.18) : Color.gray.opacity(0.10)), radius: 6, x: 0, y: 2)
        )
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: alignment)
    }
}
