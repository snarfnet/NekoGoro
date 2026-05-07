import SwiftUI
import GoogleMobileAds

struct HeartParticle: Identifiable {
    let id = UUID()
    var pos: CGPoint
    var opacity: Double = 1
    var scale: Double = 0.5
    var yOffset: Double = 0
    var symbol: String = "heart.fill"
    var color: Color = Color(hex: "#FF6EB4")
}

struct PettingView: View {
    @StateObject private var haptics = HapticManager()
    @StateObject private var audio = AudioManager()
    @StateObject private var videoController = CatVideoController()

    @State private var mood: CatMood = .idle
    @State private var strokeCount = 0
    @State private var isPetting = false
    @State private var heartParticles: [HeartParticle] = []
    @State private var moodText = ""
    @State private var showMoodText = false
    @State private var pressStart: Date?
    @State private var shakeOffset: CGFloat = 0
    @State private var purringTimer: Timer?
    @State private var tapCount = 0

    @AppStorage("totalPetStrokes") private var totalPetStrokes = 0
    @AppStorage("treatsGiven") private var treatsGiven = 0
    @AppStorage("bondPoints") private var bondPoints = 0
    @AppStorage("firstLaunchDate") private var firstLaunchDate = ""

    @State private var showStats = false
    @State private var treatParticles: [HeartParticle] = []
    @State private var treatCooldown = false

    private var bondLevel: Int { min(bondPoints / 50, 10) }
    private var bondProgress: Double { Double(bondPoints % 50) / 50.0 }
    private var moodTitle: String {
        switch mood {
        case .idle: return "なでてね"
        case .purring: return "ごろごろ中"
        case .happy: return "ごきげん"
        case .angry: return "ちょっと休憩"
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                AmbientBackdrop()

                if videoController.playerReady {
                    CatVideoView(controller: videoController)
                        .ignoresSafeArea()
                        .offset(x: shakeOffset)
                } else {
                    VideoPlaceholder()
                        .ignoresSafeArea()
                }

                LinearGradient(
                    colors: [.black.opacity(0.32), .clear, .black.opacity(0.46)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                particleLayer

                if showMoodText {
                    MoodBadge(text: moodText)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.82).combined(with: .opacity),
                            removal: .scale(scale: 1.12).combined(with: .opacity)
                        ))
                }

                VStack(spacing: 0) {
                    TopStatusBar(
                        bondLevel: bondLevel,
                        progress: bondProgress,
                        mood: moodTitle,
                        showStats: { showStats = true }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 54)

                    Spacer()

                    BottomControls(
                        isPetting: isPetting,
                        strokeCount: strokeCount,
                        treatCooldown: treatCooldown,
                        giveTreat: { giveTreat(in: geo) }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    BannerAdView()
                        .frame(height: 50)
                        .background(.black.opacity(0.18))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(petGesture(in: geo))
            .simultaneousGesture(TapGesture().onEnded { triggerTap() })
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showStats) { StatsView() }
        .onAppear {
            videoController.setup()
            if firstLaunchDate.isEmpty {
                firstLaunchDate = ISO8601DateFormatter().string(from: Date())
            }
        }
    }

    private var particleLayer: some View {
        ZStack {
            ForEach(heartParticles) { particle in
                Image(systemName: particle.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(particle.color)
                    .shadow(color: particle.color.opacity(0.45), radius: 10)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(x: particle.pos.x, y: particle.pos.y + particle.yOffset)
            }

            ForEach(treatParticles) { particle in
                Image(systemName: particle.symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(particle.color)
                    .shadow(color: particle.color.opacity(0.4), radius: 8)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(x: particle.pos.x, y: particle.pos.y + particle.yOffset)
            }
        }
        .allowsHitTesting(false)
    }

    private func petGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let catFrame = CGRect(x: 0, y: 0, width: geo.size.width, height: geo.size.height - 50)
                let inZone = catFrame.contains(value.location)

                if inZone && !isPetting {
                    isPetting = true
                    pressStart = Date()
                    mood = .purring
                    haptics.startPurring()
                    audio.startPurring()
                    videoController.startPetting()
                    startPurringTimer()
                }

                if inZone, let startedAt = pressStart, Date().timeIntervalSince(startedAt) > 1.5 {
                    triggerAngry()
                    pressStart = nil
                }
            }
            .onEnded { _ in
                guard isPetting else { return }
                isPetting = false
                pressStart = nil
                purringTimer?.invalidate()
                purringTimer = nil
                haptics.stopPurring()
                audio.stopPurring()
                videoController.stopPetting()
                videoController.advanceStroke()

                strokeCount += 1
                totalPetStrokes += 1
                bondPoints += 1
                if strokeCount >= 22 { triggerHappyMeow() }

                withAnimation(.easeOut(duration: 0.5)) { mood = .idle }
            }
    }

    private func triggerHappyMeow() {
        strokeCount = 0
        videoController.reset()
        mood = .happy
        haptics.playMeow()
        audio.playMeow()
        showMoodLabel("にゃー")
        spawnHearts()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { mood = .idle }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard mood == .idle else { return }
            audio.playSleepyMeow()
            showMoodLabel("zzz...")
        }
    }

    private func triggerAngry() {
        guard mood != .angry else { return }
        isPetting = false
        strokeCount = max(0, strokeCount - 3)
        mood = .angry
        haptics.stopPurring()
        audio.stopPurring()
        videoController.stopPetting()
        haptics.playAngryMeow()
        audio.playAngryMeow()
        showMoodLabel("にゃっ")
        withAnimation(.interpolatingSpring(stiffness: 400, damping: 10)) { shakeOffset = -12 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 10)) { shakeOffset = 12 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 10)) { shakeOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { mood = .idle }
        }
    }

    private func startPurringTimer() {
        purringTimer?.invalidate()
        purringTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3.5...5.5), repeats: false) { _ in
            guard self.isPetting else { return }
            if Int.random(in: 0...1) == 0 {
                self.audio.playChattering()
                self.showMoodLabel("カカカ")
            } else {
                self.audio.playTrill()
                self.showMoodLabel("るるる")
            }
        }
    }

    private func triggerTap() {
        guard mood == .idle else { return }
        tapCount += 1
        if tapCount % 3 == 0 {
            audio.playKittenMeow()
            showMoodLabel("みゃっ")
        } else {
            audio.playTrill()
            showMoodLabel("るるる")
        }
    }

    private func showMoodLabel(_ text: String) {
        moodText = text
        withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) { showMoodText = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.24)) { showMoodText = false }
        }
    }

    private func giveTreat(in geo: GeometryProxy) {
        guard !treatCooldown else { return }
        treatCooldown = true
        treatsGiven += 1
        bondPoints += 5
        haptics.playMeow()
        audio.playMeow()
        showMoodLabel("おいしい")

        for _ in 0..<5 {
            let particle = HeartParticle(
                pos: CGPoint(
                    x: CGFloat.random(in: geo.size.width * 0.2...geo.size.width * 0.8),
                    y: CGFloat.random(in: geo.size.height * 0.3...geo.size.height * 0.6)
                ),
                symbol: "fish.fill",
                color: Color(hex: "#FFB347")
            )
            treatParticles.append(particle)
            if let index = treatParticles.firstIndex(where: { $0.id == particle.id }) {
                withAnimation(.easeOut(duration: 1.2)) {
                    treatParticles[index].opacity = 0
                    treatParticles[index].scale = 1.3
                    treatParticles[index].yOffset = -60
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    treatParticles.removeAll { $0.id == particle.id }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            treatCooldown = false
        }
    }

    private func spawnHearts() {
        for _ in 0..<6 {
            let particle = HeartParticle(
                pos: CGPoint(x: CGFloat.random(in: 80...220), y: CGFloat.random(in: 80...200)),
                symbol: "heart.fill",
                color: Color(hex: "#FF6EB4")
            )
            heartParticles.append(particle)
            if let index = heartParticles.firstIndex(where: { $0.id == particle.id }) {
                withAnimation(.easeOut(duration: 1.4)) {
                    heartParticles[index].opacity = 0
                    heartParticles[index].scale = 1.4
                    heartParticles[index].yOffset = -70
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    heartParticles.removeAll { $0.id == particle.id }
                }
            }
        }
    }
}

private struct AmbientBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "#1B1514"), Color(hex: "#3A211B"), Color(hex: "#151515")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [Color(hex: "#FFB347").opacity(0.24), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )
        )
        .ignoresSafeArea()
    }
}

private struct VideoPlaceholder: View {
    var body: some View {
        ZStack {
            AmbientBackdrop()
            VStack(spacing: 18) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 88, weight: .regular))
                    .foregroundStyle(Color(hex: "#FFE2C2"))
                    .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
                Text("猫の動画を読み込み中")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }
}

private struct TopStatusBar: View {
    let bondLevel: Int
    let progress: Double
    let mood: String
    let showStats: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(Color(hex: "#FFB347"))
                    Text("NekoGoro")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 8) {
                    Text("Lv.\(bondLevel)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#FFE2C2"))
                    ProgressView(value: progress)
                        .tint(Color(hex: "#FF6EB4"))
                        .frame(width: 96)
                    Text(mood)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }

            Spacer()

            Button(action: showStats) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.14), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.2)))
            }
            .accessibilityLabel("記録を開く")
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.16)))
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
    }
}

private struct BottomControls: View {
    let isPetting: Bool
    let strokeCount: Int
    let treatCooldown: Bool
    let giveTreat: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: isPetting ? "waveform.path.ecg" : "hand.draw.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isPetting ? Color(hex: "#FF6EB4") : Color(hex: "#FFE2C2"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(isPetting ? "そのままゆっくり" : "猫をなでる")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(strokeCount)/22 でごきげん")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.64))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.15)))

            Button(action: giveTreat) {
                VStack(spacing: 4) {
                    Image(systemName: "fish.fill")
                        .font(.system(size: 23, weight: .bold))
                    Text("おやつ")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(width: 78, height: 68)
                .background(
                    LinearGradient(
                        colors: treatCooldown
                            ? [Color.gray.opacity(0.55), Color.gray.opacity(0.36)]
                            : [Color(hex: "#FF9F43"), Color(hex: "#FF6EB4")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.18)))
                .shadow(color: treatCooldown ? .clear : Color(hex: "#FF6EB4").opacity(0.24), radius: 16, y: 8)
            }
            .disabled(treatCooldown)
            .accessibilityLabel("おやつをあげる")
        }
    }
}

private struct MoodBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 42, weight: .heavy, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "#FFF1C7"), Color(hex: "#FFB347"), Color(hex: "#FF6EB4")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.black.opacity(0.24), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.18)))
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }
}

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = "ca-app-pub-9404799280370656/9357373620"
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ view: BannerView, context: Context) {}
}
