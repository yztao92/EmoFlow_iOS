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
    @State private var isLoadingDetail = false
    @State private var useCustomBackground: Bool = true // 控制是否使用自定义背景
    @State private var backgroundStyle: BackgroundStyle = .grid // 背景样式
    // 用于截图的ID
    private let contentCaptureID = "noteContentCapture"

    var body: some View {
        ZStack {
            // 背景
            CustomBackgroundView(
                style: backgroundStyle,
                emotionColor: getEmotionBackgroundColor()
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 根据是否有聊天记录决定显示内容
                if record.messages.isEmpty {
                    // 没有聊天记录时，只显示笔记内容
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(record.summary)
                                .font(.body)
                            HStack {
                                Spacer()
                                Text(formattedDate(record.date))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                } else {
                    // 有聊天记录时，显示TabView
                    TabView(selection: $selectedPage) {
                        // 笔记内容页
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(record.summary)
                                    .font(.body)
                                HStack {
                                    Spacer()
                                    Text(formattedDate(record.date))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        .tag(0)

                        // 聊天记录页
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(record.messages, id: \.id) { msg in
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
                            }
                            .padding()
                        }
                        .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }

                // 按钮暂时隐藏
                // if selectedPage == 0 {
                //     HStack(spacing: 24) {
                //         Button(action: {
                //             captureNoteContent()
                //         }) {
                //             HStack {
                //                 Image(systemName: "square.and.arrow.up")
                //                 Text("分享")
                //             }
                //             .frame(maxWidth: .infinity)
                //             .padding()
                //             .background(Color(.systemGroupedBackground))
                //             .cornerRadius(12)
                //         }
                //         Button(action: {
                //             editedSummary = record.summary
                //             editedTitle = record.title ?? "今日心情"  // 设置标题初始值
                //             showEditSheet = true
                //         }) {
                //             HStack {
                //                 Image(systemName: "pencil")
                //                 Text("编辑")
                //             }
                //             .frame(maxWidth: .infinity)
                //             .padding()
                //             .background(Color(.systemGroupedBackground))
                //             .cornerRadius(12)
                //         }
                //     }
                //     .padding(.horizontal, 32)
                //     .padding(.top, 8)
                // }
                // 点状分页指示器 - 只在有聊天记录时显示
                if !record.messages.isEmpty {
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(record.title ?? "心情笔记")
                    .font(.headline).bold()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .onAppear {
            editedSummary = record.summary
            editedTitle = record.title ?? ""
            
            // 如果没有聊天记录，确保selectedPage为0
            if record.messages.isEmpty {
                selectedPage = 0
            }
            
            // 检查是否需要获取详情
            if let backendId = record.backendId {
                loadJournalDetailIfNeeded(backendId: backendId)
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
    
    // 加载日记详情（如果需要）
    private func loadJournalDetailIfNeeded(backendId: Int) {
        // 检查是否已有详情缓存
        if !JournalDetailService.shared.isDetailCached(journalId: backendId) {
            isLoadingDetail = true
            
            Task {
                do {
                    let detailedRecord = try await JournalDetailService.shared.fetchAndCacheJournalDetail(journalId: backendId)
                    await MainActor.run {
                        // 更新当前记录
                        record.messages = detailedRecord.messages
                        record.summary = detailedRecord.summary
                        record.title = detailedRecord.title
                        record.emotion = detailedRecord.emotion
                        isLoadingDetail = false
                    }
                } catch {
                    await MainActor.run {
                        isLoadingDetail = false
                        print("❌ 加载日记详情失败: \(error)")
                    }
                }
            }
        }
    }

    // 截图方法
    private func captureNoteContent() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              windowScene.windows.first(where: { $0.isKeyWindow }) != nil else { return }
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

// MARK: - 背景样式枚举
enum BackgroundStyle: String, CaseIterable {
    case grid = "网格"
    case dots = "点阵"
    case lines = "横线"
    case gradient = "渐变"
    case solid = "纯色"
}

// MARK: - 自定义背景视图
struct CustomBackgroundView: View {
    let style: BackgroundStyle
    let emotionColor: Color?
    
    init(style: BackgroundStyle, emotionColor: Color? = nil) {
        self.style = style
        self.emotionColor = emotionColor
    }
    
    var body: some View {
        ZStack {
            // 基础背景色
            if let emotionColor = emotionColor {
                emotionColor.opacity(0.3) // 降低情绪背景色的透明度
            } else {
                Color(.systemGroupedBackground)
            }
            
            // 网格始终显示，叠加在背景色上
            GridPatternView()
                .opacity(1.0) // 增加透明度，让网格更明显
        }
    }
}

// 网格线背景
struct GridPatternView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let gridSize: CGFloat = 20
                
                // 绘制垂直线
                for x in stride(from: 0, through: width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                
                // 绘制水平线
                for y in stride(from: 0, through: height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(
                Color.gray.opacity(0.2), 
                lineWidth: 0.8
            )
        }
    }
}

// 点阵背景
struct DotsPatternView: View {
    let emotionColor: Color?
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let dotSpacing: CGFloat = 25
                let dotRadius: CGFloat = 1
                
                for x in stride(from: dotSpacing, through: width - dotSpacing, by: dotSpacing) {
                    for y in stride(from: dotSpacing, through: height - dotSpacing, by: dotSpacing) {
                        let rect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                        path.addEllipse(in: rect)
                    }
                }
            }
            .fill(emotionColor?.opacity(0.4) ?? Color.gray.opacity(0.5))
        }
    }
}

// 横线背景
struct LinesPatternView: View {
    let emotionColor: Color?
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let lineSpacing: CGFloat = 30
                
                for y in stride(from: lineSpacing, through: height, by: lineSpacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(
                Color.gray.opacity(0.2), 
                lineWidth: 0.8
            )
        }
    }
}

// 渐变背景
struct GradientBackgroundView: View {
    let emotionColor: Color?
    
    var body: some View {
        if let emotionColor = emotionColor {
            LinearGradient(
                gradient: Gradient(colors: [
                    emotionColor,
                    emotionColor.opacity(0.8),
                    emotionColor
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground).opacity(0.8),
                    Color(.systemGroupedBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - 背景颜色获取方法
extension ChatrecordDetailView {
    // 根据日记情绪获取对应的背景颜色
    private func getEmotionBackgroundColor() -> Color? {
        guard let emotion = record.emotion else { return nil }
        
        // 从 EmotionData 中查找对应的背景颜色
        if let emotionData = EmotionData.emotions.first(where: { $0.assetName == emotion.iconName }) {
            return emotionData.backgroundColor
        }
        
        return nil
    }
}

