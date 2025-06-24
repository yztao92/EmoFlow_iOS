import Foundation
import SwiftUI

enum EmotionType: String, CaseIterable, Codable {  // ✅ 加上 Codable
    case angry, sad, tired, happy
}

extension EmotionType {
    var color: Color {
        switch self {
        case .angry: return .red
        case .sad: return .blue
        case .tired: return .gray
        case .happy: return .yellow
        }
    }

    var iconName: String {
        switch self {
        case .angry: return "EmojiAngry"
        case .sad: return "EmojiSad"
        case .tired: return "EmojiTired"
        case .happy: return "EmojiHappy"
        }
    }
}
