import SwiftUI

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let bottomY = height

        var path = Path()
        path.move(to: CGPoint(x: centerX, y: bottomY))

        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            control1: CGPoint(x: centerX - width * 0.4, y: bottomY - height * 0.1),
            control2: CGPoint(x: 0, y: height * 0.6)
        )

        path.addArc(
            center: CGPoint(x: width * 0.25, y: height * 0.25),
            radius: width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addArc(
            center: CGPoint(x: width * 0.75, y: height * 0.25),
            radius: width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addCurve(
            to: CGPoint(x: centerX, y: bottomY),
            control1: CGPoint(x: width, y: height * 0.6),
            control2: CGPoint(x: centerX + width * 0.4, y: bottomY - height * 0.1)
        )

        return path
    }
}
