//
//  SearchAnimationDemoView.swift
//  App-search
//
//  Created by k zhukovskaya on 20.04.2026.
//

import SwiftUI

struct SearchAnimationDemoView: View {
    private let shieldSize: CGFloat = 40
    private let shieldSpacing: CGFloat = 24
    private let shieldCount = 4
    private let compositionScale: CGFloat = 0.8
    private let fps: Double = 60
    private let loopFrames: Double = 79
    private let pauseSeconds: Double = 1.0
    private let bounceIntensity: CGFloat = 0.75
    private let glintIntensity: Double = 0.55
    private let subtitleFadeSeconds: Double = 0.18
    private let animationCycleSeconds: Double = (79.0 / 60.0) + 1.0
    private let subtitles = [
        "Готовим лучшие предложения",
        "Проверяем, все ли на месте",
        "Загружаем информацию",
        "Еще несколько секунд",
    ]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            TimelineView(.animation) { context in
                let baseTime = context.date.timeIntervalSinceReferenceDate

                VStack(spacing: 28) {
                    HStack(spacing: shieldSpacing * compositionScale) {
                        ForEach(0..<shieldCount, id: \.self) { index in
                            let phaseDelay = Double(index) * (3 / fps) // 3 frames like in the sample JSON
                            let size = shieldSize * compositionScale

                            Image("Shield")
                                .resizable()
                                .scaledToFit()
                                .frame(width: size, height: size)
                                .offset(y: bounceOffset(at: baseTime + phaseDelay, size: size))
                                .opacity(bounceOpacity(at: baseTime + phaseDelay))
                                .overlay {
                                    ShieldGlintOverlay(
                                        progress: glintProgress(at: baseTime + phaseDelay),
                                        intensity: glintIntensity
                                    )
                                    .mask {
                                        Image("Shield")
                                            .resizable()
                                            .scaledToFit()
                                    }
                            }
                        }
                    }
                    .scaleEffect(0.9)
                    .offset(y: -12)

                    VStack(spacing: 8) {
                        Text("Открываем приложение")
                            .font(.system(size: 20, weight: .bold))
                            .kerning(0.38)
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)

                        Text(subtitles[subtitleIndex(at: baseTime)])
                            .font(.system(size: 15, weight: .regular))
                            .kerning(-0.24)
                            .foregroundStyle(.black.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .opacity(subtitleOpacity(at: baseTime))
                    }
                    .padding(.top, 8)
                }
                .offset(y: -40)
            }
        }
    }

    private func subtitleIndex(at time: Double) -> Int {
        guard !subtitles.isEmpty else { return 0 }
        let cycle = Int(floor(time / animationCycleSeconds))
        let index = cycle % subtitles.count
        return max(0, min(subtitles.count - 1, index))
    }

    private func subtitleOpacity(at time: Double) -> Double {
        let t = time.truncatingRemainder(dividingBy: animationCycleSeconds)
        let fade = subtitleFadeSeconds
        if fade <= 0 { return 1 }

        let fadeIn = min(1, max(0, t / fade))
        let fadeOut = min(1, max(0, (animationCycleSeconds - t) / fade))
        return min(fadeIn, fadeOut)
    }

    private func bounceOffset(at time: Double, size: CGFloat) -> CGFloat {
        let rawY = bounceRawY(at: time)
        let scale = size / 60
        return CGFloat(rawY) * scale * bounceIntensity
    }

    private func bounceOpacity(at time: Double) -> Double {
        // 1.0 at rest/pause, slightly dimmer at the top of the bounce.
        let lift = bounceLift(at: time) // 0...1 when moving up (negative Y)
        return 1.0 - 0.22 * lift
    }

    private func bounceLift(at time: Double) -> Double {
        let rawY = bounceRawY(at: time)
        return max(0, min(1, (-rawY) / 60))
    }

    private func glintProgress(at time: Double) -> Double {
        // Trigger the glint mostly during the upward motion.
        let lift = bounceLift(at: time)
        let normalized = (lift - 0.05) / 0.85
        let clamped = max(0, min(1, normalized))
        return clamped * clamped * (3 - 2 * clamped) // smoothstep
    }

    private func bounceRawY(at time: Double) -> Double {
        let animationDuration = loopFrames / fps
        let duration = animationDuration + pauseSeconds
        let t = time.truncatingRemainder(dividingBy: duration)
        if t > animationDuration { return 0 }

        // Keyframes from the sample "Loading Spinner (Dots).json" (dot01), converted to seconds.
        // Raw values are in the JSON's pixel space.
        let keys: [(time: Double, y: Double)] = [
            (0 / fps, 0),
            (15 / fps, -60),
            (35 / fps, 40),
            (49 / fps, -10),
            (61 / fps, 6),
            (71 / fps, 0),
            (79 / fps, 0),
        ]

        guard let segmentIndex = keys.lastIndex(where: { $0.time <= t }),
              segmentIndex < keys.count - 1
        else {
            return 0
        }

        let (t0, y0) = keys[segmentIndex]
        let (t1, y1) = keys[segmentIndex + 1]
        let local = (t - t0) / max(0.0001, (t1 - t0))
        let eased = local * local * (3 - 2 * local) // smoothstep
        return y0 + (y1 - y0) * eased
    }

    private struct ShieldGlintOverlay: View {
        let progress: Double
        let intensity: Double

        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let x = (CGFloat(progress) * (width * 2.2)) - (width * 1.1)

                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.95 * intensity),
                        .clear,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: width * 0.45, height: height * 1.7)
                .rotationEffect(.degrees(-22))
                .offset(x: x, y: 0)
                .blur(radius: 0.6)
                .blendMode(.plusLighter)
                .opacity(intensity)
            }
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    SearchAnimationDemoView()
}
