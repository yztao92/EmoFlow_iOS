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
    let record: ChatRecord
    var onSave: ((String) -> Void)? = nil
    @Binding var navigationPath: NavigationPath
    @State private var selectedPage = 0
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
    @State private var isLoadingDetail = false
    @State private var useCustomBackground: Bool = true // 控制是否使用自定义背景
    @State private var backgroundStyle: BackgroundStyle = .grid // 背景样式
    // 用于截图的ID
    private let contentCaptureID = "noteContentCapture"
    
    // 计算属性：根据日记情绪获取对应的背景颜色
    private var emotionBackgroundColor: Color? {
        guard let emotion = record.emotion else { 
            return nil 
        }
        
        // 根据情绪类型返回对应的 light 颜色
        switch emotion {
        case .happy:
            return ColorManager.Happy.light
        case .sad:
            return ColorManager.Sad.light
        case .angry:
            return ColorManager.Angry.light
        case .peaceful:
            return ColorManager.Peaceful.light
        case .happiness:
            return ColorManager.Happiness.light
        case .unhappy:
            return ColorManager.Unhappy.light
        }
    }
    
    // 计算属性：根据日记情绪获取对应的次要颜色
    private var emotionSecondaryColor: Color {
        guard let emotion = record.emotion else { 
            return .primary 
        }
        
        // 根据情绪类型返回对应的 secondary 颜色
        switch emotion {
        case .happy:
            return ColorManager.Happy.secondary
        case .sad:
            return ColorManager.Sad.secondary
        case .angry:
            return ColorManager.Angry.secondary
        case .peaceful:
            return ColorManager.Peaceful.secondary
        case .happiness:
            return ColorManager.Happiness.secondary
        case .unhappy:
            return ColorManager.Unhappy.secondary
        }
    }

    var body: some View {
        ZStack {
            // 背景
            CustomBackgroundView(
                style: backgroundStyle,
                emotionColor: emotionBackgroundColor
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 根据是否有聊天记录决定显示内容
                if record.messages.isEmpty {
                    // 没有聊天记录时，显示笔记内容（使用共享组件）
                    ScrollView(.vertical, showsIndicators: true) { // 明确指定垂直滚动并显示滚动指示器
                        JournalContentView(
                            emotion: record.emotion,
                            title: record.title,
                            content: record.summary,
                            date: record.date,
                            originalTimeString: record.originalTimeString
                        )
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height - 200) // 确保有足够的最小高度
                    }
                } else {
                    // 有聊天记录时，显示TabView
                    TabView(selection: $selectedPage) {
                        // 笔记内容页（使用共享组件）
                        ScrollView(.vertical, showsIndicators: true) { // 明确指定垂直滚动并显示滚动指示器
                            JournalContentView(
                                emotion: record.emotion,
                                title: record.title,
                                content: record.summary,
                                date: record.date,
                                originalTimeString: record.originalTimeString
                            )
                            .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height - 200) // 确保有足够的最小高度
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
                                                .background(Color.gray.opacity(0.18))
                                                .foregroundColor(.primary)
                                                .cornerRadius(16)
                                            Spacer()
                                        } else {
                                            Spacer()
                                            Text(msg.content)
                                                .padding(12)
                                                .background(ColorManager.inputFieldColor)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                // 只在笔记内容页（selectedPage == 0）和有聊天记录时显示按钮
                if !record.messages.isEmpty && selectedPage == 0 {
                    HStack(spacing: 16) {
                        // 分享按钮
                        Button(action: {
                            captureNoteContent()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(emotionSecondaryColor)
                        }
                        
                        // 编辑按钮
                        Button(action: {
                            navigationPath.append(AppRoute.journalEdit(record: record))
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(emotionSecondaryColor)
                        }
                    }
                } else if record.messages.isEmpty {
                    // 没有聊天记录时，总是显示按钮
                    HStack(spacing: 16) {
                        // 分享按钮
                        Button(action: {
                            captureNoteContent()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(emotionSecondaryColor)
                        }
                        
                        // 编辑按钮
                        Button(action: {
                            navigationPath.append(AppRoute.journalEdit(record: record))
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(emotionSecondaryColor)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .onAppear {
            // 如果没有聊天记录，确保selectedPage为0
            if record.messages.isEmpty {
                selectedPage = 0
            }
            
            // 移除重复的数据加载逻辑，因为 JournalDetailContainerView 已经处理了
            // 检查是否需要获取详情
            // if let backendId = record.backendId {
            //     loadJournalDetailIfNeeded(backendId: backendId)
            // }
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
                emotionColor // 使用完整的情绪颜色，不降低透明度
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



