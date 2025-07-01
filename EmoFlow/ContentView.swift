import SwiftUI
import UIKit

struct ContentView: View {
    @Binding var showChatSheet: Bool
    @Binding var emotions: [EmotionType]

    @State private var selectedEmotion: EmotionType?
    @State private var triggeredEmotion: EmotionType?  // ✅ 用于最终触发
    @State private var isHolding = false
    @State private var didTrigger = false

    @State private var fillOpacity: Double = 0
    @State private var heartScale: CGFloat = 1.0

    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
    @State private var feedbackTimer: Timer?
    @State private var vibrationInterval: Double = 0

    @State private var scaleFillTimer: Timer?
    @State private var animationStart: Date?

    private let pressDuration: Double = 5.0
    private let emotionOrder: [EmotionType] = [.happy, .tired, .sad, .angry]

    var body: some View {
        NavigationStack {
            VStack {
                Text(greeting)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading).padding(.top, 8)

                Spacer()

                ZStack {
                    HeartShape()
                        .stroke(selectedEmotion?.color ?? .gray, lineWidth: 3)
                        .frame(width: 200, height: 180)
                        .scaleEffect(heartScale)

                    HeartShape()
                        .fill(selectedEmotion?.color ?? .clear)
                        .frame(width: 200, height: 180)
                        .opacity(fillOpacity)
                        .scaleEffect(heartScale)
                }

                Spacer()

                HStack(spacing: 32) {
                    ForEach(emotionOrder, id: \.self) { emotion in
                        EmotionBubble(emotion: emotion)
                            .opacity(selectedEmotion == nil || selectedEmotion == emotion ? 1 : 0.4)
                            .allowsHitTesting(selectedEmotion == nil || selectedEmotion == emotion)
                            .gesture(
                                LongPressGesture(minimumDuration: pressDuration)
                                    .onChanged { _ in
                                        guard !isHolding else { return }
                                        isHolding = true
                                        didTrigger = false
                                        selectedEmotion = emotion     // ✅ 提前设置用于动画
                                        triggeredEmotion = emotion    // ✅ 同时记录最终触发的情绪
                                        startVibration()
                                        startHeartAnimation()
                                    }
                                    .onEnded { _ in
                                        guard isHolding && !didTrigger else { return }
                                        triggerChat()
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { _ in
                                        guard isHolding && !didTrigger else { return }
                                        triggerChat()
                                    }
                            )
                    }
                }
                .padding(.bottom, 64)
            }
            .padding()
            .onAppear(perform: resetState)
            .onChange(of: showChatSheet) { oldValue, newValue in
                if newValue == false {
                    resetState()  // ✅ 修复气泡禁用问题
                }
            }
        }
    }

    private func triggerChat() {
        didTrigger = true
        isHolding = false
        stopAll()
        emotions = [triggeredEmotion ?? .happy]  // ✅ 用最终记录的情绪传递
        showChatSheet = true
    }

    private func startVibration() {
        feedbackTimer?.invalidate()
        vibrationInterval = pressDuration / 8
        heavyFeedback.prepare()
        scheduleVibration()
    }

    private func scheduleVibration() {
        guard isHolding && !didTrigger else { return }
        heavyFeedback.impactOccurred()
        vibrationInterval = max(0.05, vibrationInterval * 0.7)
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: vibrationInterval, repeats: false) { _ in
            scheduleVibration()
        }
    }

    private func startHeartAnimation() {
        animationStart = Date()
        scaleFillTimer?.invalidate()
        scaleFillTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            guard isHolding && !didTrigger, let start = animationStart else {
                timer.invalidate()
                return
            }
            let progress = min(Date().timeIntervalSince(start) / pressDuration, 1)
            heartScale  = 1 + CGFloat(progress)
            fillOpacity = progress
            if progress >= 1 { timer.invalidate() }
        }
    }

    private func stopAll() {
        feedbackTimer?.invalidate()
        scaleFillTimer?.invalidate()
    }

    private func resetState() {
        selectedEmotion = nil
        triggeredEmotion = nil
        fillOpacity     = 0
        heartScale      = 1
        isHolding       = false
        didTrigger      = false
        stopAll()
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "上午好，现在心情咋样呀？"
        case 12..<18: return "下午好，现在心情咋样呀？"
        default:     return "晚上好，现在心情咋样呀？"
        }
    }
}
