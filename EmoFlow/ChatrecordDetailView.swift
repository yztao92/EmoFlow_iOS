// ChatRecordDetailView.swift
import SwiftUI

struct ChatRecordDetailView: View {
    let record: ChatRecord
    @State private var showAllMessages = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 头部信息
                HStack {
                    Image(record.safeEmotion.iconName)
                        .resizable()
                        .frame(width: 28, height: 28)
                    Text("心情日记")
                        .font(.title2).bold()
                    Spacer()
                    Text(record.date.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)
                
                // 摘要
                // Text("摘要")
                //     .font(.headline)
                //     .padding(.bottom, 4)
                Text(record.summary)
                    .font(.body)
                    .padding(.bottom, 16)
                
                // 聊天记录
                Text("聊天记录")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                LazyVStack(spacing: 12) {
                    ForEach(showAllMessages ? record.messages : Array(record.messages.prefix(2))) { message in
                        ChatMessageRow(message: message, record: record)
                    }
                    if record.messages.count > 2 {
                        Button(showAllMessages ? "收起" : "展开全部") {
                            showAllMessages.toggle()
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatMessageRow: View {
    let message: ChatMessage
    let record: ChatRecord

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                Image("AIicon")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                TextBubbleView(
                    text: message.content,
                    color: Color.gray.opacity(0.18),
                    alignment: .leading
                )
                Spacer()
            } else {
                Spacer()
                TextBubbleView(
                    text: message.content,
                    color: record.safeEmotion.color.opacity(0.95),
                    alignment: .trailing
                )
                Image(record.safeEmotion.iconName)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// 删除了TextBubbleView的重复定义，直接复用ChatMessagesView.swift中的TextBubbleView
