import AVFoundation
import Combine

class AudioManager: ObservableObject {
    private let engine = AVAudioEngine()
    private let purrNode = AVAudioPlayerNode()
    private var purrBuffer: AVAudioPCMBuffer?
    private var isPlaying = false
    private let sampleRate: Double = 44100

    init() {
        setupAudio()
        purrBuffer = makePurrBuffer()
    }

    private func setupAudio() {
        engine.attach(purrNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(purrNode, to: engine.mainMixerNode, format: format)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch { print("Audio engine error: \(error)") }
    }

    private func makePurrBuffer() -> AVAudioPCMBuffer? {
        // 1秒のゴロゴロ音ループバッファ
        let frameCount = AVAudioFrameCount(sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let ptr = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            // 2Hzのトレモロ（ゴロゴロリズム）
            let tremolo = (sin(2 * .pi * 2.0 * t) * 0.35 + 0.65)
            // 25Hz基音 + 倍音
            let wave = sin(2 * .pi * 25 * t) * 0.45
                     + sin(2 * .pi * 50 * t) * 0.25
                     + sin(2 * .pi * 100 * t) * 0.15
                     + sin(2 * .pi * 150 * t) * 0.08
            // ノイズでリアル感
            let noise = Double.random(in: -0.04...0.04)
            ptr[i] = Float((wave + noise) * tremolo * 0.35)
        }
        return buffer
    }

    func startPurring() {
        guard !isPlaying, let buf = purrBuffer else { return }
        isPlaying = true
        purrNode.scheduleBuffer(buf, at: nil, options: .loops)
        purrNode.play()
    }

    func stopPurring() {
        guard isPlaying else { return }
        isPlaying = false
        purrNode.stop()
    }

    func playMeow() {
        // にゃーん: 300Hz→600Hz→450Hz スイープ
        DispatchQueue.global().async { [weak self] in
            self?.playSweep(startHz: 320, peakHz: 640, endHz: 400, duration: 0.5, volume: 0.6)
        }
    }

    func playAngryMeow() {
        // にゃっ！: 鋭いバースト
        DispatchQueue.global().async { [weak self] in
            self?.playSweep(startHz: 700, peakHz: 900, endHz: 600, duration: 0.12, volume: 0.8)
        }
    }

    func playTrill() {
        // トリル: 挨拶の声 rrrrr
        DispatchQueue.global().async { [weak self] in
            self?.playTrillSound(baseHz: 550, duration: 0.55, volume: 0.55)
        }
    }

    func playSleepyMeow() {
        // 眠そうな声: ゆっくり下降
        DispatchQueue.global().async { [weak self] in
            self?.playSweep(startHz: 360, peakHz: 370, endHz: 170, duration: 0.9, volume: 0.45)
        }
    }

    func playKittenMeow() {
        // 子猫の声: 高く短い
        DispatchQueue.global().async { [weak self] in
            self?.playSweep(startHz: 680, peakHz: 880, endHz: 620, duration: 0.28, volume: 0.55)
        }
    }

    func playChattering() {
        // チャタリング: 鳥を見た時の素早いクリック音
        DispatchQueue.global().async { [weak self] in
            self?.playChatterBursts()
        }
    }

    private func playTrillSound(baseHz: Double, duration: Double, volume: Double) {
        let frames = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buf.frameLength = frames
        let ptr = buf.floatChannelData![0]
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let progress = Double(i) / Double(frames)
            let freq = baseHz + sin(2 * .pi * 28 * t) * 70
            let envelope = sin(.pi * progress)
            ptr[i] = Float(sin(2 * .pi * freq * t) * envelope * volume * 0.5)
        }
        let tempNode = AVAudioPlayerNode()
        engine.attach(tempNode)
        engine.connect(tempNode, to: engine.mainMixerNode, format: format)
        tempNode.scheduleBuffer(buf, at: nil) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.engine.detach(tempNode)
            }
        }
        tempNode.play()
    }

    private func playChatterBursts() {
        let totalDuration = 0.9
        let frames = AVAudioFrameCount(sampleRate * totalDuration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buf.frameLength = frames
        let ptr = buf.floatChannelData![0]
        let burstPeriod = 0.09
        let burstDur = 0.055
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let burstIdx = Int(t / burstPeriod)
            let burstT = t.truncatingRemainder(dividingBy: burstPeriod)
            if burstIdx < 9 && burstT < burstDur {
                let freq = 560.0 + Double(burstIdx % 3) * 25.0
                let env = sin(.pi * burstT / burstDur)
                ptr[i] = Float(sin(2 * .pi * freq * t) * env * 0.38)
            } else {
                ptr[i] = 0
            }
        }
        let tempNode = AVAudioPlayerNode()
        engine.attach(tempNode)
        engine.connect(tempNode, to: engine.mainMixerNode, format: format)
        tempNode.scheduleBuffer(buf, at: nil) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.engine.detach(tempNode)
            }
        }
        tempNode.play()
    }

    private func playSweep(startHz: Double, peakHz: Double, endHz: Double, duration: Double, volume: Double) {
        let frames = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buf.frameLength = frames
        let ptr = buf.floatChannelData![0]
        let halfFrames = Double(frames) / 2
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let progress = Double(i) / Double(frames)
            // 周波数スイープ: start→peak→end
            let freq: Double
            if progress < 0.5 {
                freq = startHz + (peakHz - startHz) * (progress * 2)
            } else {
                freq = peakHz + (endHz - peakHz) * ((progress - 0.5) * 2)
            }
            // エンベロープ（サイン形状）
            let envelope = sin(.pi * progress)
            // 猫声らしいビブラート
            let vibrato = 1.0 + sin(2 * .pi * 6 * t) * 0.03
            ptr[i] = Float(sin(2 * .pi * freq * vibrato * t) * envelope * volume * 0.5)
        }
        let tempNode = AVAudioPlayerNode()
        engine.attach(tempNode)
        engine.connect(tempNode, to: engine.mainMixerNode, format: format)
        tempNode.scheduleBuffer(buf, at: nil) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.engine.detach(tempNode)
            }
        }
        tempNode.play()
    }
}
