// ChatRecordDetailView.swift
import SwiftUI
import UIKit
import WebKit
import ObjectiveC

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
                            if isLoadingDetail {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: emotionSecondaryColor))
                                    .scaleEffect(0.8)
                            } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(emotionSecondaryColor)
                            }
                        }
                        .disabled(isLoadingDetail)
                        
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
                            if isLoadingDetail {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: emotionSecondaryColor))
                                    .scaleEffect(0.8)
                            } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(emotionSecondaryColor)
                            }
                        }
                        .disabled(isLoadingDetail)
                        
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
    
    // 截图方法 - 使用完整HTML生成完美截图
    private func captureNoteContent() {
        // 显示加载状态
        isLoadingDetail = true
        
        // 生成完整HTML内容
        let htmlContent = generateCompleteHTML()
        print("🔍 生成的HTML内容长度: \(htmlContent.count)")
        
        // 创建WKWebView配置
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // 创建WKWebView
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 800), configuration: configuration)
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        // 设置WebView的代理来监听加载状态
        let webViewDelegate = WebViewDelegate {
            DispatchQueue.main.async {
                self.captureWebView(webView)
            }
        }
        
        // 设置delegate
        webView.navigationDelegate = webViewDelegate
        
        // 保持对delegate的引用，防止被释放
        objc_setAssociatedObject(webView, "delegate", webViewDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 加载HTML内容
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        // 设置超时，防止无限等待
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.isLoadingDetail == true {
                print("⚠️ 截图超时，强制截图")
                self.captureWebView(webView)
            }
        }
    }
    
    // 使用WKWebView生成截图
    private func captureWebView(_ webView: WKWebView) {
        // 使用更可靠的JavaScript来检测内容是否完全加载
        let checkContentScript = """
        (function() {
            // 检查图片是否加载完成
            const images = document.querySelectorAll('img');
            let loadedImages = 0;
            let totalImages = images.length;
            
            if (totalImages === 0) {
                return { height: document.body.scrollHeight, ready: true };
            }
            
            return new Promise((resolve) => {
                images.forEach(img => {
                    if (img.complete) {
                        loadedImages++;
                        if (loadedImages === totalImages) {
                            resolve({ height: document.body.scrollHeight, ready: true });
                        }
                    } else {
                        img.onload = () => {
                            loadedImages++;
                            if (loadedImages === totalImages) {
                                resolve({ height: document.body.scrollHeight, ready: true });
                            }
                        };
                        img.onerror = () => {
                            loadedImages++;
                            if (loadedImages === totalImages) {
                                resolve({ height: document.body.scrollHeight, ready: true });
                            }
                        };
                    }
                });
            });
        })();
        """
        
        webView.evaluateJavaScript(checkContentScript) { result, error in
            if let error = error {
                print("❌ JavaScript执行错误: \(error)")
                // 如果JavaScript执行失败，使用默认高度
                DispatchQueue.main.async {
                    self.captureWithDefaultHeight(webView)
                }
                return
            }
            
            // 处理JavaScript结果
            if let resultDict = result as? [String: Any],
               let height = resultDict["height"] as? CGFloat,
               let ready = resultDict["ready"] as? Bool,
               ready {
                
                DispatchQueue.main.async {
                    self.captureWithCalculatedHeight(webView, contentHeight: height)
                }
            } else {
                // 如果结果格式不对，使用默认高度
                DispatchQueue.main.async {
                    self.captureWithDefaultHeight(webView)
                }
            }
        }
    }
    
    // 使用计算的高度进行截图
    private func captureWithCalculatedHeight(_ webView: WKWebView, contentHeight: CGFloat) {
        let targetWidth: CGFloat = 600 // 固定宽度，确保一致性
        let targetHeight = max(contentHeight + 80, 800) // 加上边距，最小高度800px
        
        print("🔍 计算的高度: \(contentHeight), 目标高度: \(targetHeight)")
        
        // 设置WebView尺寸
        webView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        
        // 等待一下确保视图完全渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.generateScreenshot(webView, size: CGSize(width: targetWidth, height: targetHeight))
        }
    }
    
    // 使用默认高度进行截图
    private func captureWithDefaultHeight(_ webView: WKWebView) {
        let targetWidth: CGFloat = 600
        let targetHeight: CGFloat = 1000 // 默认高度
        
        print("🔍 使用默认高度: \(targetHeight)")
        
        webView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.generateScreenshot(webView, size: CGSize(width: targetWidth, height: targetHeight))
        }
    }
    
    // 生成最终截图
    private func generateScreenshot(_ webView: WKWebView, size: CGSize) {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            webView.drawHierarchy(in: webView.bounds, afterScreenUpdates: true)
        }
        
        print("✅ 截图生成成功，尺寸: \(size)")
        
        // 更新UI
        self.shareImage = image
        self.showShareSheet = true
        self.isLoadingDetail = false
    }
    
    // 计算分享图片的预估高度，确保内容完整显示
    private func calculateEstimatedHeight() -> CGFloat {
        let baseHeight: CGFloat = 200 // 基础高度：情绪图标 + 标题 + 基础内容
        let iconHeight: CGFloat = 128 // 情绪图标高度
        let titleHeight: CGFloat = 50 // 标题预估高度
        let contentPadding: CGFloat = 32 // 内容区域的内边距
        
        // 根据内容长度估算内容高度
        let contentLength = record.summary.count
        let estimatedContentHeight: CGFloat
        
        if contentLength < 100 {
            estimatedContentHeight = 100
        } else if contentLength < 300 {
            estimatedContentHeight = 150
        } else if contentLength < 600 {
            estimatedContentHeight = 250
        } else {
            estimatedContentHeight = 350
        }
        
        let totalHeight = baseHeight + iconHeight + titleHeight + contentPadding + estimatedContentHeight
        
        // 确保最小高度，最大不超过屏幕高度的80%
        let minHeight: CGFloat = 600
        let maxHeight = UIScreen.main.bounds.height * 0.8
        
        return max(minHeight, min(totalHeight, maxHeight))
    }
    
    // 生成完整的HTML页面，包含情绪图标、标题、正文、背景等所有元素
    private func generateCompleteHTML() -> String {
        let emotionIconPath = getEmotionIconPath()
        let title = record.title ?? "今日心情"
        let content = sanitizeHTML(record.summary)
        let backgroundColor = getEmotionBackgroundColor()
        let secondaryColor = getEmotionSecondaryColor()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    background: \(backgroundColor);
                    min-height: 100vh;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: flex-start;
                    padding: 20px;
                }
                
                .container {
                    width: 100%;
                    max-width: 600px;
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 20px;
                    padding: 30px;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
                }
                
                .emotion-icon {
                    width: 128px;
                    height: 128px;
                    margin: 0 auto 30px;
                    display: block;
                    border-radius: 16px;
                    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
                }
                
                .title {
                    font-size: 28px;
                    font-weight: 600;
                    text-align: center;
                    margin: 0 0 30px 0;
                    color: #000;
                    line-height: 1.3;
                    word-wrap: break-word;
                }
                
                .content {
                    font-size: 20px;
                    font-weight: 300;
                    line-height: 1.8;
                    text-align: left;
                    color: #000;
                    margin: 0;
                }
                
                .content p {
                    margin: 0 0 20px 0;
                    text-align: justify;
                }
                
                .content p:last-child {
                    margin-bottom: 0;
                }
                
                /* 支持HTML内容的样式 */
                .content strong, .content b {
                    font-weight: 600;
                }
                
                .content em, .content i {
                    font-style: italic;
                }
                
                .content h1, .content h2, .content h3 {
                    font-weight: 600;
                    margin: 25px 0 15px 0;
                    text-align: center;
                }
                
                .content ul, .content ol {
                    text-align: left;
                    margin: 15px 0;
                    padding-left: 25px;
                }
                
                .content li {
                    margin: 8px 0;
                    text-align: justify;
                }
                
                .content blockquote {
                    border-left: 4px solid \(secondaryColor);
                    padding-left: 20px;
                    margin: 20px 0;
                    font-style: italic;
                    color: #666;
                }
                
                .content code {
                    background: rgba(0, 0, 0, 0.1);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: "SF Mono", Monaco, monospace;
                    font-size: 18px;
                }
                
                .content pre {
                    background: rgba(0, 0, 0, 0.1);
                    padding: 15px;
                    border-radius: 8px;
                    overflow-x: auto;
                    margin: 20px 0;
                }
                
                .content pre code {
                    background: none;
                    padding: 0;
                }
            </style>
        </head>
        <body>
            <div class="container">
                \(emotionIconPath.isEmpty ? "" : "<img src=\"\(emotionIconPath)\" class=\"emotion-icon\" alt=\"情绪图标\">")
                <h1 class="title">\(title)</h1>
                <div class="content">\(content)</div>
            </div>
        </body>
        </html>
        """
    }
    
    // 获取情绪图标的正确文件路径
    private func getEmotionIconPath() -> String {
        guard let emotion = record.emotion else { return "" }
        let iconName = emotion.iconName ?? "Happy"
        
        // 尝试获取PNG格式的图片路径
        if let path = Bundle.main.path(forResource: iconName, ofType: "png") {
            return "file://" + path
        }
        
        // 如果PNG不存在，尝试其他格式
        if let path = Bundle.main.path(forResource: iconName, ofType: "jpg") {
            return "file://" + path
        }
        
        // 如果都不存在，返回空字符串，HTML中会隐藏图标
        print("⚠️ 未找到情绪图标: \(iconName)")
        return ""
    }
    
    // 清理和验证HTML内容
    private func sanitizeHTML(_ html: String) -> String {
        var sanitized = html
        
        // 确保HTML标签完整
        if !sanitized.contains("<html>") && !sanitized.contains("<body>") {
            // 如果只是纯HTML片段，包装成完整HTML
            sanitized = """
            <div>\(sanitized)</div>
            """
        }
        
        // 处理特殊字符
        sanitized = sanitized.replacingOccurrences(of: "&", with: "&amp;")
        sanitized = sanitized.replacingOccurrences(of: "<", with: "&lt;")
        sanitized = sanitized.replacingOccurrences(of: ">", with: "&gt;")
        sanitized = sanitized.replacingOccurrences(of: "\"", with: "&quot;")
        sanitized = sanitized.replacingOccurrences(of: "'", with: "&#39;")
        
        // 恢复HTML标签
        sanitized = sanitized.replacingOccurrences(of: "&lt;div&gt;", with: "<div>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/div&gt;", with: "</div>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;p&gt;", with: "<p>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/p&gt;", with: "</p>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;br&gt;", with: "<br>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;strong&gt;", with: "<strong>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/strong&gt;", with: "</strong>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;em&gt;", with: "<em>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/em&gt;", with: "</em>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;h1&gt;", with: "<h1>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/h1&gt;", with: "</h1>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;h2&gt;", with: "<h2>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/h2&gt;", with: "</h2>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;h3&gt;", with: "<h3>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/h3&gt;", with: "</h3>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;ul&gt;", with: "<ul>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/ul&gt;", with: "</ul>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;ol&gt;", with: "<ol>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/ol&gt;", with: "</ol>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;li&gt;", with: "<li>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/li&gt;", with: "</li>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;blockquote&gt;", with: "<blockquote>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/blockquote&gt;", with: "</blockquote>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;code&gt;", with: "<code>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/code&gt;", with: "</code>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;pre&gt;", with: "<pre>")
        sanitized = sanitized.replacingOccurrences(of: "&lt;/pre&gt;", with: "</pre>")
        
        return sanitized
    }
    
    // 获取情绪背景色（HTML格式）
    private func getEmotionBackgroundColor() -> String {
        guard let emotion = record.emotion else { return "#FFFFFF" }
        
        switch emotion {
        case .happy:
            return "#FFE8F0" // ColorManager.Happy.light
        case .sad:
            return "#E8F4FF" // ColorManager.Sad.light
        case .angry:
            return "#FFE8E8" // ColorManager.Angry.light
        case .peaceful:
            return "#F0F8FF" // ColorManager.Peaceful.light
        case .happiness:
            return "#FFF8E8" // ColorManager.Happiness.light
        case .unhappy:
            return "#F8F0FF" // ColorManager.Unhappy.light
        }
    }
    
    // 获取情绪次要色（HTML格式）
    private func getEmotionSecondaryColor() -> String {
        guard let emotion = record.emotion else { return "#007AFF" }
        
        switch emotion {
        case .happy:
            return "#FF6B9D" // ColorManager.Happy.secondary
        case .sad:
            return "#4A90E2" // ColorManager.Sad.secondary
        case .angry:
            return "#FF6B6B" // ColorManager.Angry.secondary
        case .peaceful:
            return "#6B9DFF" // ColorManager.Peaceful.light
        case .happiness:
            return "#FFB84A" // ColorManager.Happiness.secondary
        case .unhappy:
            return "#9D6BFF" // ColorManager.Unhappy.secondary
        }
    }
}

// MARK: - WebViewDelegate
class WebViewDelegate: NSObject, WKNavigationDelegate {
    private let onLoadComplete: () -> Void
    
    init(onLoadComplete: @escaping () -> Void) {
        self.onLoadComplete = onLoadComplete
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ WebView加载完成")
        onLoadComplete()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView加载失败: \(error)")
        onLoadComplete() // 即使失败也尝试截图
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView临时导航失败: \(error)")
        onLoadComplete() // 即使失败也尝试截图
    }
}

// 移除不再使用的formattedDate函数，因为新的分享逻辑不再需要它

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



