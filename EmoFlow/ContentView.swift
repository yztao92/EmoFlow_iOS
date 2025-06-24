import SwiftUI
import UIKit  // 用于触感反馈

struct ContentView: View {
    @State private var selectedEmotion: EmotionType?
    @State private var showChatSheet = false
    @State private var isHolding = false
    @State private var didTrigger = false

    @State private var fillOpacity: Double = 0
    @State private var heartScale: CGFloat = 1.0

    // 触感反馈
    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
    @State private var feedbackTimer: Timer?
    @State private var vibrationInterval: Double = 0

    // 心形动画
    @State private var scaleFillTimer: Timer?
    @State private var animationStart: Date?

    // 长按阈值
    private let pressDuration: Double = 5.0

    // 气泡顺序
    private let emotionOrder: [EmotionType] = [.happy, .tired, .sad, .angry]

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
                HStack(spacing: 32) {
                    ForEach(emotionOrder, id: \.self) { emotion in
                        EmotionBubble(emotion: emotion)
                            .opacity(selectedEmotion == nil ? 1 : 0.4)
                            .allowsHitTesting(selectedEmotion == nil)
                            // 1️⃣ 长按手势：负责“满时长”分支
                            .gesture(
                                LongPressGesture(minimumDuration: pressDuration)
                                    .onChanged { _ in
                                        guard !isHolding else { return }
                                        isHolding = true
                                        didTrigger = false
                                        selectedEmotion = emotion
                                        // 启动触感 & 心形动画
                                        startVibration()
                                        startHeartAnimation()
                                    }
                                    .onEnded { _ in
                                        // 满 5 秒后触发
                                        guard isHolding && !didTrigger else { return }
                                        triggerChat()
                                    }
                            )
                            // 2️⃣ 拖拽手势：负责“中途松手”分支
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
            .sheet(isPresented: $showChatSheet, onDismiss: resetState) {
                ChatView(emotions: [selectedEmotion ?? .happy])
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: 逻辑封装
    private func triggerChat() {
        didTrigger = true
        isHolding = false
        stopAll()
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
