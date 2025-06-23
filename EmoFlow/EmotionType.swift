import Foundation
import SwiftUI

enum EmotionType: String, CaseIterable {
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
}
