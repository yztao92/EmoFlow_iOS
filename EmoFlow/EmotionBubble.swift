import SwiftUI

struct EmotionBubble: View {
    let emotion: EmotionType
    @State private var isDragging = false
    @State private var isDropped = false

    var emoji: String {
        switch emotion {
        case .angry: return "😡"
        case .sad: return "😢"
        case .tired: return "😩"
        case .happy: return "😊"
        }
    }

    var background: Color {
        switch emotion {
        case .angry: return .red
        case .sad: return .blue
        case .tired: return .gray
        case .happy: return .yellow
        }
    }

    var body: some View {
        Text(emoji)
            .font(.system(size: 36))
            .padding(20)
            .background(emotion.color)
            .clipShape(Circle())
            .scaleEffect(isDropped ? 0.0 : (isDragging ? 1.2 : 1.0))
            .shadow(radius: isDragging ? 6 : 3)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isDragging)
            .opacity(isDropped ? 0 : 1)
            .onDrag {
                isDragging = true
                return NSItemProvider(object: emotion.rawValue as NSString)
            }
            .onDrop(of: [.text], isTargeted: nil) { _ in
                withAnimation {
                    isDropped = true
                    isDragging = false
                }
                return true
            }
    }
}
