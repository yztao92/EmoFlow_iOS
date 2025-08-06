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
        // 强制设置字体大小为20px，确保与编辑器一致
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableAttributedString.length)
        
        // 强制设置字体大小为20px
        mutableAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 20), range: fullRange)
        
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