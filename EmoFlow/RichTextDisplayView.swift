import SwiftUI

struct RichTextDisplayView: View {
    let attributedString: NSAttributedString
    let textColor: Color
    let isScrollEnabled: Bool
    
    init(attributedString: NSAttributedString, textColor: Color = .primary, isScrollEnabled: Bool = true) {
        self.attributedString = attributedString
        self.textColor = textColor
        self.isScrollEnabled = isScrollEnabled
    }
    
    var body: some View {
        VStack {
            // 使用SwiftUI的Text组件显示富文本内容
            Text(attributedString.string)
                .font(.system(size: 20, weight: .light)) // 确保与编辑时完全一致
                .foregroundColor(Color(.label)) // 使用系统标签颜色，与编辑时保持一致
                .multilineTextAlignment(.center)
                .lineSpacing(10) // 确保与编辑时的10点行间距一致
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .frame(
            minHeight: RichTextDisplayView.calculateHeight(for: attributedString, width: UIScreen.main.bounds.width - 32),
            alignment: .top
        )
    }
    
    // 计算内容高度，供外部使用
    static func calculateHeight(for attributedString: NSAttributedString, width: CGFloat) -> CGFloat {
        let availableWidth = width - 64 // 减去左右边距
        let estimatedHeight = attributedString.boundingRect(
            with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height
        return max(estimatedHeight + 40, 140) // 加上边距，最小高度140
    }
}

// MARK: - 从HTML创建NSAttributedString的扩展
extension String {
    func htmlToAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: .utf8) else { 
            return nil 
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return attributedString
        } catch {
            return nil
        }
    }
} 