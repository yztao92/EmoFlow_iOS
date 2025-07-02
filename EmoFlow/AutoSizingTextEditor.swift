import SwiftUI

struct AutoSizingTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var dynamicHeight: CGFloat
    var minHeight: CGFloat = 36
    var maxHeight: CGFloat = 100
    var font: UIFont = .systemFont(ofSize: 17)

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.font = font
        textView.backgroundColor = UIColor.clear
        textView.delegate = context.coordinator
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 2, bottom: 8, right: 2)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        if #available(iOS 13.0, *) {
            textView.overrideUserInterfaceStyle = .unspecified
        }
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        AutoSizingTextEditor.recalculateHeight(view: uiView, result: $dynamicHeight, minHeight: minHeight, maxHeight: maxHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $dynamicHeight, minHeight: minHeight, maxHeight: maxHeight)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var height: Binding<CGFloat>
        var minHeight: CGFloat
        var maxHeight: CGFloat

        init(text: Binding<String>, height: Binding<CGFloat>, minHeight: CGFloat, maxHeight: CGFloat) {
            self.text = text
            self.height = height
            self.minHeight = minHeight
            self.maxHeight = maxHeight
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
            AutoSizingTextEditor.recalculateHeight(view: textView, result: height, minHeight: minHeight, maxHeight: maxHeight)
        }
    }

    static func recalculateHeight(view: UITextView, result: Binding<CGFloat>, minHeight: CGFloat, maxHeight: CGFloat) {
        let size = view.sizeThatFits(CGSize(width: view.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(size.height, minHeight), maxHeight)
        if result.wrappedValue != newHeight {
            DispatchQueue.main.async {
                result.wrappedValue = newHeight
            }
        }
    }
} 