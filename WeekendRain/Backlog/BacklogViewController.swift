import AppKit

public final class BacklogViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let entries: [BacklogEntry]
    private let tableView = NSTableView()

    public init(entries: [BacklogEntry]) {
        self.entries = entries
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.entries = []
        super.init(coder: coder)
    }

    public override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 760, height: 520))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        tableView.headerView = nil
        tableView.rowHeight = 58
        tableView.intercellSpacing = NSSize(width: 0, height: 8)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear

        let speakerColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("speaker"))
        speakerColumn.width = 120
        tableView.addTableColumn(speakerColumn)

        let textColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("text"))
        textColumn.width = 600
        tableView.addTableColumn(textColumn)

        scrollView.documentView = tableView
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -18)
        ])
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        let speakerWidth = min(max(view.bounds.width * 0.20, 104), 150)
        tableView.tableColumns.first(where: { $0.identifier.rawValue == "speaker" })?.width = speakerWidth
        tableView.tableColumns.first(where: { $0.identifier.rawValue == "text" })?.width = max(tableView.bounds.width - speakerWidth - 12, 240)
    }

    public func numberOfRows(in tableView: NSTableView) -> Int {
        entries.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let entry = entries[row]
        let identifier = tableColumn?.identifier.rawValue ?? "text"
        let label = NSTextField(wrappingLabelWithString: identifier == "speaker" ? entry.speaker : entry.text)
        label.font = identifier == "speaker"
            ? NSFont.systemFont(ofSize: 13, weight: .semibold)
            : NSFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = identifier == "speaker"
            ? NSColor.labelColor
            : NSColor.secondaryLabelColor
        label.maximumNumberOfLines = 3
        return label
    }
}
