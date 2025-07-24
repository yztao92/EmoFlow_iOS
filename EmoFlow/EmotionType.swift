import Foundation
import SwiftUI

enum EmotionType: String, CaseIterable, Codable {  // ✅ 加上 Codable
    case angry, sad, unhappy, happy, peaceful, happiness
}

extension EmotionType {
    var color: Color {
        switch self {
        case .angry: return .red
        case .sad: return .blue
        case .unhappy: return .gray
        case .happy: return .yellow
        case .peaceful: return .mint
        case .happiness: return .pink
        }
    }

    var iconName: String {
        switch self {
        case .angry: return "Angry"
        case .sad: return "Sad"
        case .unhappy: return "Unhappy"
        case .happy: return "Happy"
        case .peaceful: return "Peaceful"
        case .happiness: return "Happiness"
        }
    }

    var displayName: String {
        switch self {
        case .happy: return "开心"
        case .unhappy: return "不开心"
        case .sad: return "悲伤"
        case .angry: return "愤怒"
        case .peaceful: return "平和"
        case .happiness: return "幸福"
        }
    }
}
