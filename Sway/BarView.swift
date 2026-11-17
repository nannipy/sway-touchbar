import AppKit

final class BarContentView: NSView {
    private var zones: [BarZone: [NSView]] = [:]
    private var scrolls: [BarZone: ControlBandView] = [:]
    private var preferredWidth: NSLayoutConstraint!
    private let appsScroll: NSScrollView
    init(apps: NSStackView) {
        appsScroll = NSScrollView()
        super.init(frame: NSRect(x: 0, y: 0, width: 1085, height: 30))
        appsScroll.documentView = apps
        appsScroll.drawsBackground = false
        appsScroll.hasHorizontalScroller = true
        appsScroll.autohidesScrollers = true
        appsScroll.scrollerStyle = .overlay
        for zone in BarZone.allCases {
            let scroll = ControlBandView()
            scrolls[zone] = scroll
            addSubview(scroll)
        }
        // Touch Bar compresses this single item to the available modal-bar width.
        preferredWidth = widthAnchor.constraint(equalToConstant: 1085)
        preferredWidth.priority = NSLayoutConstraint.Priority(999)
        preferredWidth.isActive = true
        heightAnchor.constraint(equalToConstant: 30).isActive = true
        setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
        setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1), for: .horizontal)
    }
    required init?(coder: NSCoder) { fatalError() }
    override var intrinsicContentSize: NSSize { NSSize(width: preferredWidth?.constant ?? 1085, height: 30) }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        synchronizeWidth()
    }
    private func synchronizeWidth() {
        guard let width = window?.contentView?.bounds.width, width > 0,
              abs(preferredWidth.constant - width) > 0.5 else { return }
        preferredWidth.constant = width
        invalidateIntrinsicContentSize()
        needsLayout = true
    }
    func configure(_ layout: BarLayout, views: [BarWidget: NSView]) {
        for zone in BarZone.allCases {
            for view in scrolls[zone]!.documentView.subviews { view.removeFromSuperview() }
        }
        for band in scrolls.values { band.resetScroll() }
        zones.removeAll()
        for zone in BarZone.allCases {
            let children = layout.widgets(in: zone).compactMap { widget -> NSView? in
                widget == .apps ? appsScroll : views[widget]
            }
            zones[zone] = children
            for child in children { scrolls[zone]!.documentView.addSubview(child) }
        }
        needsLayout = true
    }
    private func desiredWidth(_ view: NSView) -> CGFloat {
        if view === appsScroll { return 180 }
        if let adjustment = view as? AdjustmentView { return CGFloat(adjustment.segmentCount) * 44 + 8 }
        if view is NSButton { return 44 }
        return max(0, view.intrinsicContentSize.width)
    }
    private func naturalWidth(_ zone: BarZone) -> CGFloat {
        let children = zones[zone] ?? []
        return children.reduce(0) { $0 + desiredWidth($1) } + CGFloat(max(0, children.count - 1)) * 6
    }
    override func layout() {
        super.layout()
        synchronizeWidth()
        let geometry = BarGeometry(width: bounds.width, height: bounds.height, centerWidth: naturalWidth(.center))
        for (zone, region) in [(BarZone.left, geometry.left), (.center, geometry.center), (.right, geometry.right)] {
            let children = zones[zone] ?? []
            let hasApps = children.contains { $0 === appsScroll }
            let fixed = children.filter { $0 !== appsScroll }.reduce(CGFloat(0)) { $0 + desiredWidth($1) }
                + CGFloat(max(0, children.count - 1)) * 6
            let appWidth = max(36, region.width - fixed)
            let contentWidth = hasApps ? fixed + appWidth : naturalWidth(zone)
            let viewportWidth = min(region.width, contentWidth)
            var viewport = region
            viewport.size.width = viewportWidth
            if zone == .right { viewport.origin.x = region.maxX - viewportWidth }
            if zone == .center { viewport.origin.x = bounds.midX - viewportWidth / 2 }
            let scroll = scrolls[zone]!
            scroll.frame = viewport
            scroll.contentWidth = contentWidth
            scroll.needsLayout = true
            var x: CGFloat = 0
            for child in children {
                let width = child === appsScroll ? appWidth : desiredWidth(child)
                let height: CGFloat = child === appsScroll ? bounds.height : (child is NSTextField ? min(28, child.intrinsicContentSize.height) : 28)
                child.frame = NSRect(x: x, y: (bounds.height - height) / 2, width: width, height: height)
                x += width + 6
            }
        }
    }
}


final class BatteryView: NSView {
    private let icon = NSImageView()
    private let percentLabel = NSTextField(labelWithString: "—")
    override init(frame: NSRect) {
        super.init(frame: frame)
        percentLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        percentLabel.textColor = .white
        addSubview(icon); addSubview(percentLabel)
    }
    required init?(coder: NSCoder) { fatalError() }
    func update(percent: Int?, charging: Bool) {
        icon.image = batteryIcon(percent: percent)
        let text = percent.map { "\($0)%" } ?? "—"
        percentLabel.stringValue = "\(charging ? "ϟ " : "")\(text)"
        setAccessibilityElement(true)
        setAccessibilityLabel("Batteria \(text)\(charging ? ", in carica" : "")")
        invalidateIntrinsicContentSize(); needsLayout = true
    }
    // Round glyph metrics outwards and reserve space for the percent sign's overhang.
    override var intrinsicContentSize: NSSize { NSSize(width: 29 + ceil(percentLabel.intrinsicContentSize.width) + 6, height: 28) }
    override func layout() {
        super.layout()
        icon.frame = NSRect(x: 0, y: (bounds.height - 12) / 2, width: 25, height: 12)
        let size = percentLabel.intrinsicContentSize
        percentLabel.frame = NSRect(x: 29, y: floor((bounds.height - ceil(size.height)) / 2), width: ceil(size.width) + 4, height: ceil(size.height))
    }
}


// NSScrollView installs a direct-touch pan recognizer which cancels descendant
// controls after a few points. Control bands clip without recognizing pans;
// dense custom layouts use explicit paging buttons instead.
final class ControlBandView: NSView {
    let documentView = NSView()
    private let clip = NSClipView()
    private let previous = NSButton()
    private let next = NSButton()
    var contentWidth: CGFloat = 0
    private var offset: CGFloat = 0
    override init(frame: NSRect) {
        super.init(frame: frame)
        clip.drawsBackground = false
        clip.documentView = documentView
        addSubview(clip)
        for (button, symbol, label, action) in [
            (previous, "chevron.left", "Scorri elementi a sinistra", #selector(pageLeft)),
            (next, "chevron.right", "Scorri elementi a destra", #selector(pageRight))] {
            button.bezelStyle = .rounded
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
            button.imagePosition = .imageOnly
            button.setAccessibilityLabel(label)
            button.target = self; button.action = action
            addSubview(button)
        }
    }
    convenience init() { self.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError() }
    override func layout() {
        super.layout()
        let overflowing = contentWidth > bounds.width + 0.5
        let arrowWidth = overflowing ? min(CGFloat(20), bounds.width / 3) : 0
        previous.isHidden = !overflowing; next.isHidden = !overflowing
        previous.frame = NSRect(x: 0, y: 1, width: arrowWidth, height: 28)
        next.frame = NSRect(x: bounds.width - arrowWidth, y: 1, width: arrowWidth, height: 28)
        clip.frame = bounds.insetBy(dx: arrowWidth, dy: 0)
        documentView.frame = NSRect(x: 0, y: 0, width: contentWidth, height: bounds.height)
        offset = min(max(0, contentWidth - clip.bounds.width), max(0, offset))
        clip.scroll(to: NSPoint(x: offset, y: 0))
        previous.isEnabled = offset > 0
        next.isEnabled = offset < contentWidth - clip.bounds.width - 0.5
    }
    func resetScroll() { offset = 0; needsLayout = true }
    @objc private func pageLeft() { offset -= max(44, clip.bounds.width * 0.7); needsLayout = true }
    @objc private func pageRight() { offset += max(44, clip.bounds.width * 0.7); needsLayout = true }
}
