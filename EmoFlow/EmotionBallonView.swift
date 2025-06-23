import SwiftUI

struct EmotionBalloonView: View {
    @State private var moodScore: Double = 5

    var animationName: String {
        switch moodScore {
        case 1...2: return "balloon_sad"
        case 3...5: return "balloon_neutral"
        case 6...7: return "balloon_happy"
        case 8...10: return "balloon_happy"
        default: return "balloon_neutral"
        }
    }

    var body: some View {
        VStack(spacing: 40) {
            Text("今天的你感觉如何？")
                .font(.title2)
                .bold()

            LottieView(animationName: animationName)
                .frame(width: 180, height: 180)

            Slider(value: $moodScore, in: 1...10, step: 1)
                .padding(.horizontal)
        }
    }
}//
