import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String

    class Coordinator {
        var animationView: LottieAnimationView?

        init(animationView: LottieAnimationView?) {
            self.animationView = animationView
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(animationView: nil)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: animationName)

        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.translatesAutoresizingMaskIntoConstraints = false

        // ✅ 添加初始播放
        animationView.play()

        containerView.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])

        context.coordinator.animationView = animationView
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = context.coordinator.animationView else { return }

        if let animation = LottieAnimation.named(animationName) {
            animationView.animation = animation
            animationView.play()
            print("✅ 播放动画：\(animationName)")
        } else {
            print("❌ 找不到动画：\(animationName)")
        }
    }
}
