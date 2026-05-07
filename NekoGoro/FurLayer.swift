import SwiftUI

struct Hair {
    let pos: CGPoint
    let naturalAngle: Double
    var angle: Double
    var opacity: Double = 0.55
}

class FurModel: ObservableObject {
    var hairs: [Hair] = []
    var size: CGSize = .zero

    func setup(in rect: CGRect) {
        guard rect.width > 0, size != rect.size else { return }
        size = rect.size
        hairs = []
        let cols = Int(rect.width / 9)
        let rows = Int(rect.height / 9)
        for row in 0..<rows {
            for col in 0..<cols {
                let x = rect.minX + CGFloat(col) * 9 + 4.5 + CGFloat.random(in: -2...2)
                let y = rect.minY + CGFloat(row) * 9 + 4.5 + CGFloat.random(in: -2...2)
                // 自然な毛並み（体の中心から外向き）
                let cx = rect.midX, cy = rect.midY
                let dx = x - cx, dy = y - cy
                let natural = atan2(dy, dx) + Double.pi / 2
                let jitter = Double.random(in: -0.3...0.3)
                hairs.append(Hair(pos: CGPoint(x: x, y: y),
                                  naturalAngle: natural + jitter,
                                  angle: natural + jitter))
            }
        }
    }

    func updateTouch(at pos: CGPoint, direction: CGVector, strength: Double = 1.0) {
        let radius: Double = 55
        for i in hairs.indices {
            let dx = Double(pos.x - hairs[i].pos.x)
            let dy = Double(pos.y - hairs[i].pos.y)
            let dist = sqrt(dx*dx + dy*dy)
            if dist < radius {
                let influence = (1 - dist/radius) * strength
                let dragAngle = atan2(direction.dy, direction.dx) + Double.pi / 2
                hairs[i].angle += (dragAngle - hairs[i].angle) * influence * 0.5
                hairs[i].opacity = min(0.8, 0.55 + influence * 0.25)
            }
        }
    }

    func returnToNatural(dt: Double = 0.016) {
        for i in hairs.indices {
            hairs[i].angle += (hairs[i].naturalAngle - hairs[i].angle) * dt * 3
            hairs[i].opacity += (0.55 - hairs[i].opacity) * dt * 4
        }
    }
}

struct FurLayer: View {
    @ObservedObject var model: FurModel
    let hairLength: CGFloat = 7
    let hairColor: Color

    var body: some View {
        Canvas { ctx, size in
            for hair in model.hairs {
                let dx = cos(hair.angle) * Double(hairLength / 2)
                let dy = sin(hair.angle) * Double(hairLength / 2)
                var path = Path()
                path.move(to: CGPoint(x: hair.pos.x - dx, y: hair.pos.y - dy))
                path.addLine(to: CGPoint(x: hair.pos.x + dx, y: hair.pos.y + dy))
                ctx.stroke(path,
                           with: .color(hairColor.opacity(hair.opacity)),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}
