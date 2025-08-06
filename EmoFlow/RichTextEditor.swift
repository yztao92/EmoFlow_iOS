import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var textAlignment: TextAlignment
    
    let placeholder: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.label
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineFragmentPadding = 0
        
        // 设置内容压缩和拥抱优先级
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // 更新文本内容
        if textView.text != text {
            // 解码HTML实体
            let decodedText = text
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
            
            textView.text = decodedText
        }
        
        // 更新富文本格式
        updateTextFormatting(textView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateTextFormatting(_ textView: UITextView) {
        let attributedString = NSMutableAttributedString(string: textView.text)
        
        // 应用字体样式
        let font = UIFont.systemFont(ofSize: 16)
        let boldFont = UIFont.boldSystemFont(ofSize: 16)
        let italicFont = UIFont.italicSystemFont(ofSize: 16)
        let boldItalicFont = UIFont.boldSystemFont(ofSize: 16).withTraits(.traitItalic)
        
        // 根据状态选择字体
        var selectedFont = font
        if isBold && isItalic {
            selectedFont = boldItalicFont
        } else if isBold {
            selectedFont = boldFont
        } else if isItalic {
            selectedFont = italicFont
        }
        
        // 应用字体到整个文本
        attributedString.addAttribute(.font, value: selectedFont, range: NSRange(location: 0, length: attributedString.length))
        
        // 应用对齐方式
        let paragraphStyle = NSMutableParagraphStyle()
        switch textAlignment {
        case .leading:
            paragraphStyle.alignment = .left
        case .center:
            paragraphStyle.alignment = .center
        case .trailing:
            paragraphStyle.alignment = .right
        }
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        
        textView.attributedText = attributedString
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // 通知父组件输入框获得焦点
            NotificationCenter.default.post(name: NSNotification.Name("TextEditorFocused"), object: nil)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // 通知父组件输入框失去焦点
            NotificationCenter.default.post(name: NSNotification.Name("TextEditorUnfocused"), object: nil)
        }
    }
}

// 扩展UIFont以支持粗体斜体组合
extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
} 