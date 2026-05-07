import SwiftUI

struct StatsView: View {
    @AppStorage("totalPetStrokes") private var totalPetStrokes = 0
    @AppStorage("treatsGiven") private var treatsGiven = 0
    @AppStorage("bondPoints") private var bondPoints = 0
    @AppStorage("firstLaunchDate") private var firstLaunchDateStr = ""
    @Environment(\.dismiss) private var dismiss

    private var bondLevel: Int { min(bondPoints / 50, 10) }
    private var bondProgress: Double { Double(bondPoints % 50) / 50.0 }

    private var daysWithCat: Int {
        guard !firstLaunchDateStr.isEmpty,
              let date = ISO8601DateFormatter().date(from: firstLaunchDateStr) else { return 1 }
        return max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF3E0"), Color(hex: "#FFD9C2"), Color(hex: "#F8B7B2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    bondCard
                    statsGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("記録")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#5A3326"))
                Text("今日までのなかよしメモ")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#5A3326").opacity(0.66))
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color(hex: "#5A3326"))
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.58), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.75)))
            }
            .accessibilityLabel("閉じる")
        }
    }

    private var bondCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("なかよしレベル")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#5A3326").opacity(0.72))
                    Text("Lv. \(bondLevel)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#C4622A"))
                }
                Spacer()
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(hex: "#FF6EB4"))
                    .shadow(color: Color(hex: "#FF6EB4").opacity(0.28), radius: 12, y: 6)
            }

            HStack(spacing: 6) {
                ForEach(0..<10) { index in
                    Image(systemName: index < bondLevel ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(index < bondLevel ? Color(hex: "#FF6EB4") : Color(hex: "#C4622A").opacity(0.28))
                }
            }

            if bondLevel < 10 {
                VStack(alignment: .leading, spacing: 7) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(hex: "#C4622A").opacity(0.14))
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FF6EB4"), Color(hex: "#FFB347")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * bondProgress)
                        }
                    }
                    .frame(height: 12)

                    Text("次のレベルまで \(50 - (bondPoints % 50)) pt")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#5A3326").opacity(0.62))
                }
            } else {
                Text("最高レベルに到達しました")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#FF6EB4"))
            }
        }
        .padding(20)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.8)))
        .shadow(color: Color(hex: "#8B4513").opacity(0.12), radius: 24, y: 12)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            StatCard(icon: "hand.draw.fill", label: "なでた回数", value: "\(totalPetStrokes)回", color: Color(hex: "#FF6EB4"))
            StatCard(icon: "fish.fill", label: "おやつ", value: "\(treatsGiven)回", color: Color(hex: "#FF9933"))
            StatCard(icon: "calendar.badge.clock", label: "一緒にいる日数", value: "\(daysWithCat)日", color: Color(hex: "#C4622A"))
            StatCard(icon: "star.fill", label: "なかよしポイント", value: "\(bondPoints)pt", color: Color(hex: "#FFD15C"))
        }
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#5A3326"))
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#5A3326").opacity(0.62))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .padding(16)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.78)))
        .shadow(color: Color(hex: "#8B4513").opacity(0.1), radius: 18, y: 8)
    }
}
