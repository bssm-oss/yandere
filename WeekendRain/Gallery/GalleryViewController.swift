import AppKit

public final class GalleryViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    private let assets: [VisualAsset]
    private let unlockedCG: Set<String>
    private let contentBaseURL: URL?
    private let collectionView = NSCollectionView()
    private let overlay = NSVisualEffectView()
    private let overlayImageView = NSImageView()
    private let overlayTitle = NSTextField(labelWithString: "")
    private let overlayPrompt = NSTextField(wrappingLabelWithString: "")

    public init(assets: [VisualAsset], unlockedCG: Set<String>, contentBaseURL: URL? = nil) {
        self.assets = assets.sorted { $0.id < $1.id }
        self.unlockedCG = unlockedCG
        self.contentBaseURL = contentBaseURL
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.assets = []
        self.unlockedCG = []
        self.contentBaseURL = nil
        super.init(coder: coder)
    }

    public override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 860, height: 560))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 184, height: 166)
        layout.sectionInset = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        layout.minimumInteritemSpacing = 14
        layout.minimumLineSpacing = 14

        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.backgroundColors = [.black]
        collectionView.register(GalleryItemView.self, forItemWithIdentifier: GalleryItemView.identifier)

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        view.addSubview(scrollView)

        configureOverlay()

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        updateCollectionLayout()
    }

    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        assets.count
    }

    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: GalleryItemView.identifier, for: indexPath)
        guard let galleryItem = item as? GalleryItemView else { return item }
        let asset = assets[indexPath.item]
        galleryItem.configure(asset: asset, unlocked: unlockedCG.contains(asset.id), contentBaseURL: contentBaseURL)
        return galleryItem
    }

    public func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let index = indexPaths.first?.item else { return }
        let asset = assets[index]
        guard unlockedCG.contains(asset.id) else { return }
        showOverlay(for: asset)
    }

    private func configureOverlay() {
        overlay.material = .hudWindow
        overlay.blendingMode = .withinWindow
        overlay.state = .active
        overlay.alphaValue = 0
        overlay.isHidden = true
        overlay.wantsLayer = true
        overlay.layer?.cornerRadius = 12
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        overlayImageView.imageScaling = .scaleProportionallyUpOrDown
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(overlayImageView)

        overlayTitle.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        overlayTitle.textColor = .white
        overlayTitle.lineBreakMode = .byTruncatingTail
        overlayTitle.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(overlayTitle)

        overlayPrompt.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        overlayPrompt.textColor = NSColor.white.withAlphaComponent(0.78)
        overlayPrompt.maximumNumberOfLines = 6
        overlayPrompt.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(overlayPrompt)

        let close = NSButton(title: "Close", target: self, action: #selector(hideOverlay))
        close.bezelStyle = .rounded
        close.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(close)

        NSLayoutConstraint.activate([
            overlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            overlay.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.86),
            overlay.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.82),
            overlay.widthAnchor.constraint(greaterThanOrEqualToConstant: 420),
            overlay.heightAnchor.constraint(greaterThanOrEqualToConstant: 360),

            overlayTitle.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 28),
            overlayTitle.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 26),
            overlayTitle.trailingAnchor.constraint(equalTo: close.leadingAnchor, constant: -12),

            close.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -22),
            close.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 22),

            overlayImageView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 28),
            overlayImageView.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -28),
            overlayImageView.topAnchor.constraint(equalTo: overlayTitle.bottomAnchor, constant: 18),
            overlayImageView.heightAnchor.constraint(equalTo: overlay.heightAnchor, multiplier: 0.52),

            overlayPrompt.leadingAnchor.constraint(equalTo: overlayTitle.leadingAnchor),
            overlayPrompt.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -28),
            overlayPrompt.topAnchor.constraint(equalTo: overlayImageView.bottomAnchor, constant: 18),
            overlayPrompt.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -28)
        ])
    }

    private func showOverlay(for asset: VisualAsset) {
        overlayTitle.stringValue = asset.name
        overlayPrompt.stringValue = asset.prompt
        overlayImageView.image = VisualAssetRenderer.image(for: asset, baseURL: contentBaseURL, role: .cg)
        overlay.isHidden = false
        overlay.animator().alphaValue = 1
    }

    private func updateCollectionLayout() {
        guard let layout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout else { return }
        let availableWidth = max(view.bounds.width - 36, 320)
        let spacing: CGFloat = 14
        let minimumWidth: CGFloat = 164
        let columns = max(2, Int((availableWidth + spacing) / (minimumWidth + spacing)))
        let itemWidth = floor((availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns))
        layout.itemSize = NSSize(width: itemWidth, height: floor(itemWidth * 0.62) + 58)
        layout.invalidateLayout()
    }

    @objc private func hideOverlay() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            overlay.animator().alphaValue = 0
        } completionHandler: {
            self.overlay.isHidden = true
        }
    }
}

private final class GalleryItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("GalleryItemView")

    private let thumbnailImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 184, height: 166))
        view.wantsLayer = true
        view.layer?.cornerRadius = 8
        view.layer?.borderWidth = 1

        thumbnailImageView.imageScaling = .scaleProportionallyUpOrDown
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.wantsLayer = true
        thumbnailImageView.layer?.cornerRadius = 6
        thumbnailImageView.layer?.masksToBounds = true
        view.addSubview(thumbnailImageView)

        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        statusLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = NSColor.white.withAlphaComponent(0.72)
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            thumbnailImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            thumbnailImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            thumbnailImageView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.52),

            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 10),

            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])
    }

    func configure(asset: VisualAsset, unlocked: Bool, contentBaseURL: URL?) {
        titleLabel.stringValue = unlocked ? asset.name : "LOCKED"
        statusLabel.stringValue = unlocked ? asset.id : "???"
        thumbnailImageView.image = unlocked
            ? VisualAssetRenderer.image(for: asset, baseURL: contentBaseURL, role: .cg)
            : nil
        thumbnailImageView.layer?.backgroundColor = unlocked
            ? NSColor.black.withAlphaComponent(0.24).cgColor
            : NSColor.black.withAlphaComponent(0.72).cgColor
        view.layer?.backgroundColor = unlocked
            ? NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.15, alpha: 1).cgColor
            : NSColor(calibratedWhite: 0.08, alpha: 1).cgColor
        view.layer?.borderColor = unlocked
            ? NSColor.systemRed.withAlphaComponent(0.48).cgColor
            : NSColor.white.withAlphaComponent(0.12).cgColor
    }
}
