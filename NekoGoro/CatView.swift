import SwiftUI

enum CatMood { case idle, purring, happy, angry }

struct CatView: View {
    let mood: CatMood
    @State private var blink = false
    @State private var tailAngle: Double = -10
    @State private var blushOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let headR = w * 0.38
            let bodyW = w * 0.52, bodyH = h * 0.32
            let headCY = h * 0.34, headCX = w * 0.5

            ZStack {
                // === しっぽ ===
                TailShape(angle: tailAngle)
                    .stroke(Color(hex: "#C4622A"), style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
                    .frame(width: w * 0.55, height: h * 0.3)
                    .offset(x: w * 0.22, y: h * 0.62)

                // === 体 ===
                Ellipse()
                    .fill(Color(hex: "#E8834D"))
                    .frame(width: bodyW, height: bodyH)
                    .offset(x: 0, y: h * 0.6)

                // 体のストライプ
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(Color(hex: "#C4622A").opacity(0.45))
                        .frame(width: bodyW * 0.12, height: bodyH * 0.7)
                        .offset(x: CGFloat(i - 1) * bodyW * 0.2, y: h * 0.6)
                }

                // お腹
                Ellipse()
                    .fill(Color(hex: "#FFF0DC"))
                    .frame(width: bodyW * 0.55, height: bodyH * 0.75)
                    .offset(x: 0, y: h * 0.6)

                // === 頭 ===
                Circle()
                    .fill(Color(hex: "#E8834D"))
                    .frame(width: headR * 2, height: headR * 2)
                    .position(x: headCX, y: headCY)

                // 頭のストライプ
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#C4622A").opacity(0.4))
                        .frame(width: headR * 0.15, height: headR * 0.45)
                        .offset(x: CGFloat(i - 1) * headR * 0.32)
                        .position(x: headCX, y: headCY - headR * 0.4)
                }

                // === 耳 ===
                EarShape()
                    .fill(Color(hex: "#E8834D"))
                    .frame(width: headR * 0.6, height: headR * 0.65)
                    .position(x: headCX - headR * 0.62, y: headCY - headR * 0.78)

                EarShape()
                    .fill(Color(hex: "#E8834D"))
                    .scaleEffect(x: -1, y: 1)
                    .frame(width: headR * 0.6, height: headR * 0.65)
                    .position(x: headCX + headR * 0.62, y: headCY - headR * 0.78)

                // 耳内側
                EarShape()
                    .fill(Color(hex: "#FFB5A0"))
                    .frame(width: headR * 0.35, height: headR * 0.4)
                    .position(x: headCX - headR * 0.62, y: headCY - headR * 0.78)

                EarShape()
                    .fill(Color(hex: "#FFB5A0"))
                    .scaleEffect(x: -1, y: 1)
                    .frame(width: headR * 0.35, height: headR * 0.4)
                    .position(x: headCX + headR * 0.62, y: headCY - headR * 0.78)

                // === 目 ===
                EyeView(mood: mood, blink: blink, isLeft: true)
                    .frame(width: headR * 0.42, height: headR * 0.42)
                    .position(x: headCX - headR * 0.38, y: headCY + headR * 0.05)

                EyeView(mood: mood, blink: blink, isLeft: false)
                    .frame(width: headR * 0.42, height: headR * 0.42)
                    .position(x: headCX + headR * 0.38, y: headCY + headR * 0.05)

                // === 鼻 ===
                Triangle()
                    .fill(mood == .angry ? Color(hex: "#FF6B6B") : Color(hex: "#FFB6C1"))
                    .frame(width: headR * 0.2, height: headR * 0.14)
                    .position(x: headCX, y: headCY + headR * 0.28)

                // === 口 ===
                MouthShape(mood: mood)
                    .stroke(Color(hex: "#8B4513").opacity(0.7),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: headR * 0.4, height: headR * 0.18)
                    .position(x: headCX, y: headCY + headR * 0.42)

                // === ひげ ===
                WhiskerView(side: -1, headCX: headCX, headCY: headCY, headR: headR)
                WhiskerView(side: 1, headCX: headCX, headCY: headCY, headR: headR)

                // === 幸せのほっぺ ===
                Circle()
                    .fill(Color(hex: "#FF9999").opacity(blushOpacity))
                    .frame(width: headR * 0.38, height: headR * 0.25)
                    .position(x: headCX - headR * 0.55, y: headCY + headR * 0.28)
                Circle()
                    .fill(Color(hex: "#FF9999").opacity(blushOpacity))
                    .frame(width: headR * 0.38, height: headR * 0.25)
                    .position(x: headCX + headR * 0.55, y: headCY + headR * 0.28)
            }
        }
        .onAppear { startAnimations() }
        .onChange(of: mood) { updateMoodEffects($0) }
    }

    private func startAnimations() {
        // まばたき
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.5...5), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) { blink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) { blink = false }
            }
        }
        // しっぽ揺れ
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            tailAngle = 15
        }
    }

    private func updateMoodEffects(_ mood: CatMood) {
        withAnimation(.easeInOut(duration: 0.4)) {
            blushOpacity = (mood == .happy || mood == .purring) ? 0.55 : 0
        }
    }
}

// MARK: - Sub-shapes

struct EarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct TailShape: Shape {
    var angle: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.maxX * 0.3, y: rect.minY + rect.height * 0.3),
                   control1: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY - rect.height * 0.6),
                   control2: CGPoint(x: rect.maxX * 0.6, y: rect.minY + rect.height * 0.1))
        return p
    }
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
}

struct EyeView: View {
    let mood: CatMood
    let blink: Bool
    let isLeft: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                if blink {
                    // まばたき
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h/2))
                        p.addLine(to: CGPoint(x: w, y: h/2))
                    }
                    .stroke(Color(hex: "#5C3317"), lineWidth: 2.5)
                } else {
                    switch mood {
                    case .purring, .happy:
                        // 細め・ハッピー目
                        Path { p in
                            p.move(to: CGPoint(x: w * 0.1, y: h * 0.55))
                            p.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.55),
                                           control: CGPoint(x: w * 0.5, y: h * 0.05))
                        }
                        .stroke(Color(hex: "#5C3317"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    case .angry:
                        // 怒り目
                        Circle()
                            .fill(Color(hex: "#F4B942"))
                        Circle()
                            .fill(Color.black.opacity(0.9))
                            .scaleEffect(x: 0.4, y: 0.85)
                        // 眉毛（怒り）
                        Rectangle()
                            .fill(Color(hex: "#5C3317"))
                            .frame(height: 2.5)
                            .rotationEffect(.degrees(isLeft ? -20 : 20))
                            .offset(y: -h * 0.35)
                    default:
                        // 通常目
                        Circle()
                            .fill(Color(hex: "#F4B942"))
                        Circle()
                            .fill(Color.black.opacity(0.88))
                            .scaleEffect(0.58)
                        // ハイライト
                        Circle()
                            .fill(Color.white.opacity(0.85))
                            .scaleEffect(0.18)
                            .offset(x: w * 0.1, y: -h * 0.1)
                    }
                }
            }
        }
    }
}

struct MouthShape: Shape {
    let mood: CatMood
    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch mood {
        case .happy:
            // 大きな笑顔
            p.move(to: CGPoint(x: rect.minX, y: rect.midY * 0.5))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY * 0.5),
                           control: CGPoint(x: rect.midX, y: rect.maxY))
        case .angry:
            // 逆笑顔（怒り）
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.7))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.7),
                           control: CGPoint(x: rect.midX, y: rect.minY))
        default:
            // ω 形
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addQuadCurve(to: CGPoint(x: rect.midX * 0.9, y: rect.maxY),
                           control: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                           control: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY))
        }
        return p
    }
}

struct WhiskerView: View {
    let side: CGFloat
    let headCX: CGFloat, headCY: CGFloat, headR: CGFloat

    var body: some View {
        ForEach(0..<3) { i in
            let angle = Double(i - 1) * 15.0
            let startX = headCX + side * headR * 0.15
            let startY = headCY + headR * 0.32
            Path { p in
                p.move(to: CGPoint(x: startX, y: startY))
                p.addLine(to: CGPoint(
                    x: startX + side * headR * 0.72,
                    y: startY + CGFloat(sin(angle * .pi/180)) * headR * 0.3
                ))
            }
            .stroke(Color(hex: "#8B4513").opacity(0.45),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
    }
}

// MARK: - Color extension
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
