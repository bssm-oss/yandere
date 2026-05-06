import Foundation
import CoreVideo
import QuartzCore

public protocol DisplayLinkDriver: AnyObject {
    var onFrame: ((CFTimeInterval) -> Void)? { get set }
    func start()
    func stop()
}

public final class CVDisplayLinkDriver: DisplayLinkDriver {
    public var onFrame: ((CFTimeInterval) -> Void)?
    private var displayLink: CVDisplayLink?
    private var fallbackTimer: DispatchSourceTimer?

    public init() {
        var link: CVDisplayLink?
        if CVDisplayLinkCreateWithActiveCGDisplays(&link) == kCVReturnSuccess, let link {
            displayLink = link
            CVDisplayLinkSetOutputCallback(link, Self.outputCallback, Unmanaged.passUnretained(self).toOpaque())
        }
    }

    deinit {
        stop()
    }

    public func start() {
        if let displayLink {
            CVDisplayLinkStart(displayLink)
            return
        }

        guard fallbackTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(16), leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in
            self?.onFrame?(CACurrentMediaTime())
        }
        fallbackTimer = timer
        timer.resume()
    }

    public func stop() {
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
        fallbackTimer?.cancel()
        fallbackTimer = nil
    }

    private static let outputCallback: CVDisplayLinkOutputCallback = { _, inNow, _, _, _, userInfo in
        guard let userInfo else { return kCVReturnSuccess }
        let driver = Unmanaged<CVDisplayLinkDriver>.fromOpaque(userInfo).takeUnretainedValue()
        let timeScale = inNow.pointee.videoTimeScale
        let timestamp: CFTimeInterval
        if timeScale > 0 {
            timestamp = CFTimeInterval(inNow.pointee.videoTime) / CFTimeInterval(timeScale)
        } else {
            timestamp = CACurrentMediaTime()
        }

        DispatchQueue.main.async {
            driver.onFrame?(timestamp)
        }

        return kCVReturnSuccess
    }
}

public final class ConversationEngine {
    public var onTextChanged: ((String) -> Void)?
    public var onFinished: (() -> Void)?

    public let charactersPerSecond: Double
    private let displayLink: DisplayLinkDriver
    private var glyphs: [Character] = []
    private var visibleCount = 0
    private var lastTimestamp: CFTimeInterval?
    private var fractionalProgress = 0.0
    private var finished = true

    public init(charactersPerSecond: Double = 38, displayLink: DisplayLinkDriver = CVDisplayLinkDriver()) {
        self.charactersPerSecond = charactersPerSecond
        self.displayLink = displayLink
        self.displayLink.onFrame = { [weak self] timestamp in
            self?.tick(timestamp: timestamp)
        }
    }

    public func start(text: String) {
        glyphs = Array(text)
        visibleCount = 0
        lastTimestamp = nil
        fractionalProgress = 0
        finished = glyphs.isEmpty
        onTextChanged?("")

        if finished {
            onFinished?()
        } else {
            displayLink.start()
        }
    }

    public func skip() {
        guard !finished else { return }
        visibleCount = glyphs.count
        finished = true
        displayLink.stop()
        onTextChanged?(String(glyphs))
        onFinished?()
    }

    public func stop() {
        displayLink.stop()
        finished = true
    }

    private func tick(timestamp: CFTimeInterval) {
        guard !finished else { return }

        if lastTimestamp == nil {
            lastTimestamp = timestamp
            return
        }

        let elapsed = max(0, timestamp - (lastTimestamp ?? timestamp))
        lastTimestamp = timestamp
        fractionalProgress += elapsed * charactersPerSecond

        let additionalGlyphs = Int(fractionalProgress)
        guard additionalGlyphs > 0 else { return }

        fractionalProgress -= Double(additionalGlyphs)
        visibleCount = min(glyphs.count, visibleCount + additionalGlyphs)
        onTextChanged?(String(glyphs.prefix(visibleCount)))

        if visibleCount >= glyphs.count {
            finished = true
            displayLink.stop()
            onFinished?()
        }
    }
}
