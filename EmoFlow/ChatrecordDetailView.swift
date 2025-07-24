// ChatRecordDetailView.swift
import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ChatrecordDetailView: View {
    @ObservedObject var record: ChatRecord
    var onSave: ((String) -> Void)? = nil
    @State private var selectedPage = 0
    @State private var showEditSheet = false
    @State private var editedSummary: String = ""
    @State private var editedTitle: String = ""  // 新增：编辑标题
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
    // 用于截图的ID
    private let contentCaptureID = "noteContentCapture"

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                // 移除内容区的主标题
                TabView(selection: $selectedPage) {
                    // 笔记内容页
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 添加标题
                            if let title = record.title, !title.isEmpty {
                                Text(title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 4)
                            } else {
                                Text("今日心情")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 4)
                            }
                            
                            Text(record.summary)
                                .font(.body)
                                .padding(.top, 8)
                            HStack {
                                Spacer()
                                Text(formattedDate(record.date))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .tag(0)

                    // 聊天记录页
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            let messages = record.messages
                            if !messages.isEmpty {
                                ForEach(messages, id: \ .id) { msg in
                                    HStack(alignment: .bottom, spacing: 8) {
                                        if msg.role == .assistant {
                                            Image("AIicon")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                            Text(msg.content)
                                                .padding(12)
                                                .background(Color(.darkGray))
                                                .foregroundColor(.white)
                                                .cornerRadius(16)
                                            Spacer()
                                        } else {
                                            Spacer()
                                            Text(msg.content)
                                                .padding(12)
                                                .background(Color(.secondarySystemBackground))
                                                .foregroundColor(.primary)
                                                .cornerRadius(16)
                                            Image((record.emotion?.iconName) ?? "Happy")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                                }
                            } else {
                                Text("暂无聊天记录")
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                        .padding()
                    }
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // 按钮放在分页指示器上方
                if selectedPage == 0 {
                    HStack(spacing: 24) {
                        Button(action: {
                            captureNoteContent()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("分享")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(12)
                        }
                        Button(action: {
                            editedSummary = record.summary
                            editedTitle = record.title ?? "今日心情"  // 设置标题初始值
                            showEditSheet = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("编辑")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
                // 点状分页指示器始终在最底部
                HStack(spacing: 8) {
                    ForEach(0..<2) { idx in
                        Circle()
                            .fill(selectedPage == idx ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("心情笔记")
                    .font(.headline).bold()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("编辑心情日记")
                        .font(.headline)
                        .padding(.top)
                    
                    // 标题输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标题")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("请输入标题", text: $editedTitle)
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // 内容输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    TextEditor(text: $editedSummary)
                        .font(.body)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .frame(minHeight: 200)
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("返回") {
                    showEditSheet = false
                    },
                    trailing: Button("保存") {
                    record.summary = editedSummary
                        record.title = editedTitle.isEmpty ? nil : editedTitle  // 保存标题
                    onSave?(editedSummary)
                    showEditSheet = false
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("编辑日记")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }

    // 截图方法
    private func captureNoteContent() {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let rootVC = window?.rootViewController else { return }
        let hosting = UIHostingController(rootView:
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 8) {
                        Image((record.emotion?.iconName) ?? "Happy")
                            .resizable()
                            .frame(width: 28, height: 28)
                        Text("心情日记")
                            .font(.title2).bold()
                        Spacer()
                        Text(record.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // 添加标题到分享图片
                    if let title = record.title, !title.isEmpty {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                    } else {
                        Text("今日心情")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                    }
                    
                    Text(record.summary)
                        .font(.body)
                        .padding(.top, 8)
                    HStack {
                        Spacer()
                        Text(formattedDate(record.date))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
            }
            .frame(width: UIScreen.main.bounds.width - 40)
        )
        hosting.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 400)
        let renderer = UIGraphicsImageRenderer(size: hosting.view.bounds.size)
        let image = renderer.image { ctx in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }
        self.shareImage = image
        self.showShareSheet = true
    }
}

fileprivate func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.string(from: date)
}

// 用于 GeometryReader 的 size preference
struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
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

