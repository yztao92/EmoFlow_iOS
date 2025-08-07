import SwiftUI
import UIKit

struct RichTextDisplayView: UIViewRepresentable {
    let attributedString: NSAttributedString
    let textColor: Color
    
    init(attributedString: NSAttributedString, textColor: Color = .primary) {
        self.attributedString = attributedString
        self.textColor = textColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        
        // 设置约束，确保文本视图能够正确换行
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // 保留原有的字体样式属性，只对没有字体属性的文本设置默认字体
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableAttributedString.length)
        
        // 根据当前颜色模式设置文字颜色
        let textColor: UIColor
        if UITraitCollection.current.userInterfaceStyle == .dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        
        // 遍历所有字符，设置字体和颜色
        for i in 0..<mutableAttributedString.length {
            if mutableAttributedString.attribute(.font, at: i, effectiveRange: nil) == nil {
                // 只为没有字体属性的字符设置默认字体
                mutableAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 20), range: NSRange(location: i, length: 1))
            }
            // 强制设置文字颜色，覆盖HTML中的颜色设置
            mutableAttributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: i, length: 1))
        }
        
        // 保留原有的段落样式，只添加行间距
        var i = 0
        while i < mutableAttributedString.length {
            if let existingParagraphStyle = mutableAttributedString.attribute(.paragraphStyle, at: i, effectiveRange: nil) as? NSParagraphStyle {
                // 如果已有段落样式，保留对齐方式，只修改行间距
                let newParagraphStyle = NSMutableParagraphStyle()
                newParagraphStyle.alignment = existingParagraphStyle.alignment
                newParagraphStyle.lineSpacing = 16 // 设置行间距，让文本更易读
                
                // 获取当前字符的有效范围
                var effectiveRange = NSRange()
                mutableAttributedString.attribute(.paragraphStyle, at: i, effectiveRange: &effectiveRange)
                
                // 应用新的段落样式到有效范围
                mutableAttributedString.addAttribute(.paragraphStyle, value: newParagraphStyle, range: effectiveRange)
                
                // 跳过已处理的字符
                i = effectiveRange.location + effectiveRange.length
            } else {
                // 如果没有段落样式，创建一个居中对齐的段落样式
                let newParagraphStyle = NSMutableParagraphStyle()
                newParagraphStyle.alignment = .center // 默认居中对齐
                newParagraphStyle.lineSpacing = 16 // 设置行间距，让文本更易读
                
                mutableAttributedString.addAttribute(.paragraphStyle, value: newParagraphStyle, range: NSRange(location: i, length: 1))
                i += 1
            }
        }
        
        // 更新文本容器大小，使用实际的视图宽度
        DispatchQueue.main.async {
            let availableWidth = textView.bounds.width - 16 // 减去左右边距
            textView.textContainer.size = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
        }
        
        textView.attributedText = mutableAttributedString
    }
    
    class Coordinator: NSObject {
        var parent: RichTextDisplayView
        
        init(_ parent: RichTextDisplayView) {
            self.parent = parent
        }
    }
}

// MARK: - 从HTML创建NSAttributedString的扩展
extension String {
    func htmlToAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: .utf8) else { return nil }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            return nil
        }
    }
} 