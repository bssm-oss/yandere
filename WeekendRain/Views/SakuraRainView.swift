import AppKit
import QuartzCore

open class SakuraRainView: NSView {
    private let emitter = CAEmitterLayer()
    private let rainCell = CAEmitterCell()
    private let petalCell = CAEmitterCell()

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    open override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    open override func layout() {
        super.layout()
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY + 40)
        emitter.emitterSize = CGSize(width: bounds.width, height: 8)
    }

    public func updateYandereIntensity(_ value: Int) {
        let intensity = CGFloat(value) / 100.0
        rainCell.birthRate = Float(90 + intensity * 80)
        petalCell.birthRate = Float(4 + intensity * 14)
        petalCell.color = NSColor.systemRed.withAlphaComponent(0.18 + intensity * 0.35).cgColor
        emitter.emitterCells = [rainCell, petalCell]
    }

    private func configure() {
        wantsLayer = true
        layer?.addSublayer(emitter)
        emitter.emitterShape = .line
        emitter.renderMode = .additive

        rainCell.contents = ParticleImage.rain
        rainCell.birthRate = 90
        rainCell.lifetime = 4.0
        rainCell.velocity = 360
        rainCell.velocityRange = 80
        rainCell.yAcceleration = 180
        rainCell.scale = 0.7
        rainCell.scaleRange = 0.3
        rainCell.alphaSpeed = -0.16
        rainCell.color = NSColor.white.withAlphaComponent(0.45).cgColor

        petalCell.contents = ParticleImage.petal
        petalCell.birthRate = 4
        petalCell.lifetime = 7.0
        petalCell.velocity = 72
        petalCell.velocityRange = 36
        petalCell.xAcceleration = 18
        petalCell.yAcceleration = 28
        petalCell.spin = 2.6
        petalCell.spinRange = 2.0
        petalCell.scale = 0.36
        petalCell.scaleRange = 0.18
        petalCell.alphaSpeed = -0.08
        petalCell.color = NSColor.systemPink.withAlphaComponent(0.20).cgColor

        emitter.emitterCells = [rainCell, petalCell]
    }
}

private enum ParticleImage {
    static let rain = makeImage(size: CGSize(width: 2, height: 18)) { rect in
        NSColor.white.withAlphaComponent(0.82).setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.2
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.line(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.stroke()
    }

    static let petal = makeImage(size: CGSize(width: 12, height: 8)) { rect in
        NSColor.white.withAlphaComponent(0.95).setFill()
        let path = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
        path.fill()
    }

    private static func makeImage(size: CGSize, draw: (CGRect) -> Void) -> CGImage {
        let image = NSImage(size: size)
        image.lockFocus()
        draw(CGRect(origin: .zero, size: size))
        image.unlockFocus()
        var rect = CGRect(origin: .zero, size: size)
        if let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) { return cg }
        let ctx = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8,
                           bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return ctx.makeImage()!
    }
}
