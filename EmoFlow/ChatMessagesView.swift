import SwiftUI

struct ChatMessagesView: View {
    let messages: [ChatMessage]
    let isLoading: Bool
    let userBubbleColor: Color   // 新增

    var body: some View {
        VStack(spacing: 12) {
            ForEach(messages) { message in
                HStack {
                    if message.role == .user {
                        Spacer()
                        Text(message.content)
                            .padding(12)
                            .background(userBubbleColor)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    } else {
                        Text(message.content)
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(16)
                        Spacer()
                    }
                }
                .padding(.horizontal)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
        }
    }
}
