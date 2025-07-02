import SwiftUI

struct EmotionBubble: View {
    let emotion: EmotionType
    @State private var isDragging = false  // 只用来触发放大动画
    @State private var isDropped  = false  // 只用来触发消失动画（如果你还想要的话）

    private var imageName: String {
        switch emotion {
        case .happy: return "EmojiHappy"
        case .tired: return "EmojiTired"
        case .sad:   return "EmojiSad"
        case .angry: return "EmojiAngry"
        }
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .scaleEffect(isDropped ? 0 : (isDragging ? 1.2 : 1.0))
            .shadow(color: Color.black.opacity(0.10), radius: isDragging ? 8 : 4, x: 0, y: 2)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isDragging)
            .opacity(isDropped ? 0 : 1)
            // 不再 onDrag/onDrop
    }

    /// 公开两个方法，让外部 ContentView 来驱动动画
    func pressBegin() {
        isDragging = true
    }

    func pressEnd() {
        isDragging = false
        isDropped  = true
    }
}
