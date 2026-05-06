import AppKit
import QuartzCore

public final class YandereLevelController {
    public static let shared = YandereLevelController()

    public private(set) var stats: GameStats = .defaults

    private init() {}

    public func update(stats: GameStats, sceneView: NSView, rainView: SakuraRainView?) {
        self.stats = stats
        sceneView.wantsLayer = true
        let intensity = CGFloat(stats.yandere) / 100.0
        sceneView.layer?.borderWidth = stats.yandere >= 55 ? 2 + intensity * 3 : 0
        sceneView.layer?.borderColor = NSColor.systemRed.withAlphaComponent(0.25 + intensity * 0.45).cgColor
        rainView?.updateYandereIntensity(stats.yandere)

        if stats.yandere >= 80 {
            applyShake(to: sceneView.layer, intensity: intensity)
        }
    }

    private func applyShake(to layer: CALayer?, intensity: CGFloat) {
        guard let layer else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [-4, 3, -2, 2, 0].map { CGFloat($0) * intensity }
        animation.duration = 0.18
        animation.isAdditive = true
        layer.add(animation, forKey: "weekendRain.yandereShake")
    }
}
