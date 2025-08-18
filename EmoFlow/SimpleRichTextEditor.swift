import SwiftUI
import UIKit

struct SimpleRichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    let placeholder: String
    @Binding var textViewRef: UITextView?
    var shouldFocus: Bool = false
    
    // 添加一个标志来跟踪是否应该使用 UILabel 模式
    @State private var useLabelMode: Bool = false
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 20, weight: .light) // 设置为20px，Light样式
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.label // 使用系统标签颜色，自动适应深色/浅色模式
        textView.delegate = context.coordinator
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        
        // 确保 UITextView 正确渲染富文本
        textView.allowsEditingTextAttributes = true
        textView.isEditable = true
        textView.isSelectable = true
        
        // 设置字体渲染模式，确保支持 emoji
        textView.font = .systemFont(ofSize: 20, weight: .light)
        textView.textColor = UIColor.label
        
        // 确保支持 emoji 输入
        textView.keyboardType = .default
        textView.autocorrectionType = .default
        textView.autocapitalizationType = .sentences
        
        // 设置默认的输入属性，确保新输入的文本使用默认字体
        let defaultFont = UIFont.systemFont(ofSize: 20, weight: .light)
        let defaultColor = UIColor.label
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center // 默认居中对齐
        paragraphStyle.lineSpacing = 10 // 设置行间距，让文本更易读
        
        textView.typingAttributes = [
            .font: defaultFont,
            .foregroundColor: defaultColor,
            .paragraphStyle: paragraphStyle
        ]
        
        // 设置占位符
        if attributedText.string.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.placeholderText
            // 空文本时居中对齐
            textView.textAlignment = .center
        } else {
            // 有内容时使用富文本的对齐方式
            textView.textAlignment = .left
            // 确保有内容时使用正确的文本颜色
            textView.textColor = UIColor.label
        }
        
        // 保存引用
        DispatchQueue.main.async {
            self.textViewRef = textView
        }
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // 只在内容真正改变时更新，避免光标位置重置
        if textView.attributedText != attributedText {
            textView.attributedText = attributedText
        }
        
        // 确保文本颜色正确
        if attributedText.string.isEmpty {
            textView.textColor = UIColor.placeholderText
        } else {
            textView.textColor = UIColor.label
        }
        
        // 处理自动聚焦
        if shouldFocus && !textView.isFirstResponder {
            DispatchQueue.main.async {
                textView.becomeFirstResponder()
                // 聚焦到文本末尾
                let length = textView.attributedText.length
                if length > 0 {
                    textView.selectedRange = NSRange(location: length, length: 0)
                }
            }
        }
        
        // 空文本时居中显示，有内容时使用富文本的对齐方式
        if attributedText.string.isEmpty {
            textView.textAlignment = .center
        } else {
            // 从富文本中获取对齐方式
            if attributedText.length > 0 {
                if let paragraphStyle = attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                    textView.textAlignment = paragraphStyle.alignment
                } else {
                    textView.textAlignment = .left
                }
            } else {
                textView.textAlignment = .left
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SimpleRichTextEditor
        
        init(_ parent: SimpleRichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // 清除占位符
            if textView.text == parent.placeholder {
                textView.text = ""
                textView.textColor = UIColor.label
            }
            
            // 确保新输入的文本使用默认字体属性
            let defaultFont = UIFont.systemFont(ofSize: 20, weight: .light)
            let defaultColor = UIColor.label
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center // 默认居中对齐
            paragraphStyle.lineSpacing = 10 // 设置行间距，让文本更易读
            
            textView.typingAttributes = [
                .font: defaultFont,
                .foregroundColor: defaultColor,
                .paragraphStyle: paragraphStyle
            ]
            
            // 通知父组件输入框获得焦点
            NotificationCenter.default.post(name: NSNotification.Name("TextEditorFocused"), object: nil)
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // 确保文本颜色正确
            if textView.textColor != UIColor.label && textView.text != parent.placeholder {
                textView.textColor = UIColor.label
            }
            
            // 确保新输入的文本使用默认字体属性
            let defaultFont = UIFont.systemFont(ofSize: 20, weight: .light)
            let defaultColor = UIColor.label
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center // 默认居中对齐
            paragraphStyle.lineSpacing = 10 // 设置行间距，让文本更易读
            
            textView.typingAttributes = [
                .font: defaultFont,
                .foregroundColor: defaultColor,
                .paragraphStyle: paragraphStyle
            ]
            
            // 更新绑定的富文本
            if let currentAttributedText = textView.attributedText {
                parent.attributedText = currentAttributedText
            }
            
            // 确保对齐方式在文本变化时保持一致
            if let attributedString = textView.attributedText {
                if attributedString.length > 0 {
                    if let paragraphStyle = attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                        textView.textAlignment = paragraphStyle.alignment
                    }
                } else {
                    // 空文本时保持居中对齐
                    textView.textAlignment = .center
                }
            } else {
                // 如果没有富文本，保持居中对齐
                textView.textAlignment = .center
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // 如果内容为空，显示占位符
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.placeholderText
            }
            
            // 通知父组件输入框失去焦点
            NotificationCenter.default.post(name: NSNotification.Name("TextEditorUnfocused"), object: nil)
        }
    }
}

// MARK: - 富文本工具栏
struct RichTextToolbar: View {
    let onBold: () -> Void
    let onAlignment: () -> Void
    let currentAlignment: NSTextAlignment
    
    var body: some View {
        HStack(spacing: 16) {
            // 对齐方式按钮
            Button(action: onAlignment) {
                Image(systemName: getAlignmentIcon(currentAlignment))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // 粗体按钮
            Button(action: onBold) {
                Image(systemName: "bold")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            

            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func getAlignmentIcon(_ alignment: NSTextAlignment) -> String {
        switch alignment {
        case .left:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .right:
            return "text.alignright"
        case .justified:
            return "text.aligncenter"
        case .natural:
            return "text.aligncenter"
        @unknown default:
            return "text.aligncenter"
        }
    }
}

// MARK: - UIColor 扩展
extension UIColor {
    func toHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }
}

// MARK: - 富文本工具类
class RichTextHelper {
    static func applyBold(to textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange else { return }
        
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let end = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
        let range = NSRange(location: start, length: end - start)
        
        if range.length > 0 {
            let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
            
            // 检查选中范围内是否所有字符都是粗体
            var allBold = true
            for i in range.location..<(range.location + range.length) {
                if let font = attributedString.attribute(.font, at: i, effectiveRange: nil) as? UIFont {
                    let isBold = font.fontName.contains("Bold") || font.fontName.contains("Semibold") || font.fontDescriptor.symbolicTraits.contains(.traitBold)
                    if !isBold {
                        allBold = false
                        break
                    }
                } else {
                    allBold = false
                    break
                }
            }
            
            if allBold {
                // 如果全部都是粗体，则移除粗体
                for i in range.location..<(range.location + range.length) {
                    let normalFont = UIFont.systemFont(ofSize: 20) // 改为16pt
                    attributedString.addAttribute(.font, value: normalFont, range: NSRange(location: i, length: 1))
                    
                    // 保持行间距
                    if let paragraphStyle = attributedString.attribute(.paragraphStyle, at: i, effectiveRange: nil) as? NSParagraphStyle {
                        let newParagraphStyle = NSMutableParagraphStyle()
                        newParagraphStyle.alignment = paragraphStyle.alignment
                        newParagraphStyle.lineSpacing = 8 // 保持行间距
                        attributedString.addAttribute(.paragraphStyle, value: newParagraphStyle, range: NSRange(location: i, length: 1))
                    }
                }
            } else {
                // 如果不是全部粗体，则全部设为粗体
                for i in range.location..<(range.location + range.length) {
                    let boldFont = UIFont.boldSystemFont(ofSize: 20) // 改为16pt
                    attributedString.addAttribute(.font, value: boldFont, range: NSRange(location: i, length: 1))
                    
                    // 保持行间距
                    if let paragraphStyle = attributedString.attribute(.paragraphStyle, at: i, effectiveRange: nil) as? NSParagraphStyle {
                        let newParagraphStyle = NSMutableParagraphStyle()
                        newParagraphStyle.alignment = paragraphStyle.alignment
                        newParagraphStyle.lineSpacing = 8 // 保持行间距
                        attributedString.addAttribute(.paragraphStyle, value: newParagraphStyle, range: NSRange(location: i, length: 1))
                    }
                }
            }
            
            textView.attributedText = attributedString
            
            // 手动触发 textViewDidChange 以确保更新被保存
            DispatchQueue.main.async {
                textView.delegate?.textViewDidChange?(textView)
            }
            

        }
    }
    

    
    static func setAlignment(_ alignment: NSTextAlignment, for textView: UITextView) {
        // 直接设置 UITextView 的对齐方式
        textView.textAlignment = alignment
        
        // 同时更新富文本的段落样式
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineSpacing = 10 // 设置行间距，让文本更易读
        
        // 安全地应用段落样式
        if attributedString.length > 0 {
            let fullRange = NSRange(location: 0, length: attributedString.length)
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        }
        
        // 更新富文本
        textView.attributedText = attributedString
        
        // 确保 textAlignment 与段落样式一致
        textView.textAlignment = alignment
        
        // 手动触发 textViewDidChange 以确保更新被保存
        DispatchQueue.main.async {
            textView.delegate?.textViewDidChange?(textView)
        }
    }
    
    static func convertToData(_ attributedString: NSAttributedString) -> Data? {
        // 直接序列化为Data，避免HTML转换
        return try? attributedString.data(from: NSRange(location: 0, length: attributedString.length), 
                                        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
    }
    
    static func attributedStringFromData(_ data: Data) -> NSAttributedString? {
        // 从Data反序列化，避免HTML转换
        return try? NSAttributedString(data: data, 
                                     options: [.documentType: NSAttributedString.DocumentType.rtf], 
                                     documentAttributes: nil)
    }
    
    static func convertToHTML(_ attributedString: NSAttributedString) -> String {
        // 如果富文本为空，返回空字符串
        if attributedString.length == 0 {
            return ""
        }
        
        // 使用系统原生的 HTML 转换，确保 emoji 正确处理
        let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let htmlData = try attributedString.data(from: NSRange(location: 0, length: attributedString.length), documentAttributes: documentAttributes)
            let htmlString = String(data: htmlData, encoding: .utf8) ?? ""
            
            return htmlString
        } catch {
            return ""
        }
    }
    

    
    static func htmlToAttributedString(_ htmlString: String) -> NSAttributedString {
        guard let data = htmlString.data(using: .utf8) else {
            return NSAttributedString(string: htmlString)
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return attributedString
        } catch {
            print("HTML转富文本失败: \(error)")
            return NSAttributedString(string: htmlString)
        }
    }
}



 