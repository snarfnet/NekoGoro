import SwiftUI
import AVFoundation
import Combine

class CatVideoController: ObservableObject {
    @Published var playerReady = false
    var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var totalDuration: Double = 10.0
    private var currentTime: Double = 0.0
    private let strokesPerLoop = 22

    init() {
        guard let url = Bundle.main.url(forResource: "cat_loop", withExtension: "mp4") else {
            print("⚠️ cat_loop.mp4 not found")
            return
        }
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer

        let asset = AVAsset(url: url)
        Task { @MainActor in
            if let duration = try? await asset.load(.duration) {
                totalDuration = CMTimeGetSeconds(duration)
            }
        }

        queuePlayer.pause()
        seek(to: 0)
        playerReady = true
    }

    func setup() {} // 互換性のため残す

    func startPetting() {
        player?.play()
    }

    func stopPetting() {
        player?.pause()
    }

    /// 1ストローク分だけ動画を進める
    func advanceStroke() {
        let advance = totalDuration / Double(strokesPerLoop)
        currentTime = min(currentTime + advance, totalDuration)
        seek(to: currentTime)
    }

    func reset() {
        currentTime = 0
        seek(to: 0)
    }

    private func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

struct CatVideoView: UIViewRepresentable {
    @ObservedObject var controller: CatVideoController

    class PlayerView: UIView {
        var playerLayer: AVPlayerLayer?

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = bounds
        }
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .clear

        let layer = AVPlayerLayer(player: controller.player)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        view.playerLayer = layer

        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer?.player = controller.player
    }
}
