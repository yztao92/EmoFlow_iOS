import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedEmotion: EmotionType? = nil
    @State private var showChatSheet = false
    @State private var didTrigger = false

    @State private var fillOpacity: Double = 0
    @State private var heartScale: CGFloat = 1

    // 震动
    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
    @State private var feedbackTimer: Timer?
    @State private var vibrationInterval: Double = 0

    // 心形动画
    @State private var scaleFillTimer: Timer?
    @State private var animationStart: Date?

    private let pressDuration: Double = 5.0

    var body: some View {
        NavigationStack {
            VStack {
                Text(greeting)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading).padding(.top, 8)
                Spacer()

                // 心形
                ZStack {
                    HeartShape()
                        .stroke(selectedEmotion?.color ?? .green, lineWidth: 3)
                        .frame(width: 200, height: 180)
                        .scaleEffect(heartScale)
                    HeartShape()
                        .fill(selectedEmotion?.color ?? .clear)
                        .frame(width: 200, height: 180)
                        .opacity(fillOpacity)
                        .scaleEffect(heartScale)
                }
                Spacer()

                // 情绪气泡
                HStack(spacing: 20) {
                    ForEach(EmotionType.allCases, id: \.self) { emotion in
                        EmotionBubble(emotion: emotion)
                            .opacity(selectedEmotion == nil ? 1 : 0.4)
                            .disabled(selectedEmotion != nil)
                            .onLongPressGesture(
                                minimumDuration: pressDuration,
                                pressing: { pressing in
                                    if pressing && !didTrigger {
                                        // 开始长按
                                        didTrigger = false
                                        selectedEmotion = emotion
                                        startVibration()
                                        startHeartAnimation()
                                    } else if !pressing && !didTrigger {
                                        // 中途松手
                                        didTrigger = true
                                        stopAll()
                                        showChatSheet = true
                                    }
                                },
                                perform: {
                                    // 持续满 5 秒
                                    if !didTrigger {
                                        didTrigger = true
                                        stopAll()
                                        showChatSheet = true
                                    }
                                }
                            )
                    }
                }
                .padding(.bottom, 30)
            }
            .padding()
            .onAppear(perform: resetState)
            .sheet(isPresented: $showChatSheet, onDismiss: resetState) {
                ChatView(emotions: [selectedEmotion ?? .happy])
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func startVibration() {
        feedbackTimer?.invalidate()
        vibrationInterval = pressDuration / 8
        heavyFeedback.prepare()
        scheduleVibration()
    }

    private func scheduleVibration() {
        guard !didTrigger else { return }
        heavyFeedback.impactOccurred()
        let next = max(0.05, vibrationInterval * 0.7)
        vibrationInterval = next
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: next, repeats: false) { _ in
            scheduleVibration()
        }
    }

    private func startHeartAnimation() {
        animationStart = Date()
        scaleFillTimer?.invalidate()
        scaleFillTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            guard !didTrigger, let start = animationStart else {
                timer.invalidate()
                return
            }
            let progress = min(Date().timeIntervalSince(start) / pressDuration, 1)
            heartScale = 1 + CGFloat(progress)
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
        fillOpacity     = 0
        heartScale      = 1
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
