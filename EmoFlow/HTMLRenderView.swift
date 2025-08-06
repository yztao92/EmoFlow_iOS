import SwiftUI
import WebKit

struct HTMLRenderView: UIViewRepresentable {
    let htmlContent: String
    let textColor: Color
    let isSafe: Bool
    
    init(htmlContent: String, textColor: Color, isSafe: Bool = true) {
        self.htmlContent = htmlContent
        self.textColor = textColor
        self.isSafe = isSafe
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        

        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if isSafe {
            let htmlString = createHTMLString()
            webView.loadHTMLString(htmlString, baseURL: nil)
        } else {
            // 降级为纯文本显示
            let plainText = htmlContent.htmlToString()
            let htmlString = createPlainTextHTML(plainText)
            webView.loadHTMLString(htmlString, baseURL: nil)
        }
    }
    
    private func createHTMLString() -> String {
        let textColorHex = textColor.toHex()
        
        // 检查htmlContent是否已经是完整的HTML文档
        if htmlContent.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<!DOCTYPE html") {
            // 如果已经是完整HTML，需要修复CSS样式格式
            return fixHTMLCSSFormat(htmlContent)
        } else {
            // 如果是HTML片段，包装成完整文档
            return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        font-size: 16px;
                        line-height: 1.5;
                        color: \(textColorHex);
                        margin: 0;
                        padding: 0;
                        background: transparent;
                    }
                    p {
                        margin: 0 0 12px 0;
                    }
                    img {
                        max-width: 100%;
                        height: auto;
                        border-radius: 8px;
                        margin: 8px 0;
                    }
                    strong {
                        font-weight: 600;
                    }
                    em {
                        font-style: italic;
                    }
                    .text-center {
                        text-align: center;
                    }
                    .text-left {
                        text-align: left;
                    }
                    .text-right {
                        text-align: right;
                    }
                </style>
            </head>
            <body>
                \(htmlContent)
            </body>
            </html>
            """
        }
    }
    
    private func fixHTMLCSSFormat(_ htmlString: String) -> String {
        // 修复CSS样式格式，将没有<style>标签的CSS规则包装起来
        var fixedHTML = htmlString
        
        // 查找<head>标签内的CSS规则
        if let headRange = fixedHTML.range(of: "<head>"),
           let bodyRange = fixedHTML.range(of: "<body>") {
            
            let headStart = fixedHTML.index(headRange.upperBound, offsetBy: 0)
            let headEnd = bodyRange.lowerBound
            
            let headContent = String(fixedHTML[headStart..<headEnd])
            
            // 检查是否包含CSS规则但没有<style>标签
            if headContent.contains("{") && headContent.contains("}") && !headContent.contains("<style>") {
                
                // 提取CSS规则
                let cssRules = extractCSSRules(from: headContent)
                
                // 重新构建head部分
                let newHeadContent = """
                
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                    \(cssRules)
                    </style>
                """
                
                // 替换head内容
                let newHead = "<head>\(newHeadContent)"
                fixedHTML = fixedHTML.replacingOccurrences(of: "<head>\(headContent)", with: newHead)
            }
        }
        
        return fixedHTML
    }
    
    private func extractCSSRules(from headContent: String) -> String {
        // 提取CSS规则，移除多余的空白和换行
        var cssRules = headContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        
        // 确保CSS规则格式正确
        if !cssRules.hasSuffix("}") {
            cssRules += "}"
        }
        
        return cssRules
    }
    
    private func createPlainTextHTML(_ plainText: String) -> String {
        let textColorHex = textColor.toHex()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    font-size: 16px;
                    line-height: 1.5;
                    color: \(textColorHex);
                    margin: 0;
                    padding: 0;
                    background: transparent;
                }
                p {
                    margin: 0 0 12px 0;
                }
            </style>
        </head>
        <body>
            <p>\(plainText)</p>
        </body>
        </html>
        """
    }
}

// MARK: - Color扩展
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }
} 