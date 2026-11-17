import AppKit

private final class LayoutCheckbox: NSButton { var row = 0 }
private final class LayoutZonePicker: NSPopUpButton { var row = 0 }

final class LayoutSettings: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let window: NSWindow
    private let table = NSTableView()
    private var layout: BarLayout
    private let changed: (BarLayout) -> Void
    private let dragType = NSPasteboard.PasteboardType("dev.sway.layout-widget")
    init(layout: BarLayout, changed: @escaping (BarLayout) -> Void) {
        self.layout = layout; self.changed = changed
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 650, height: 420), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        super.init()
        window.title = "Personalizza Sway"
        window.isReleasedWhenClosed = false
        let root = window.contentView!
        let description = NSTextField(wrappingLabelWithString: "Trascina le righe per riordinare gli elementi. Scegli la zona e disattiva quelli che vuoi nascondere. Le modifiche sono immediate e salvate su questo Mac.")
        description.frame = NSRect(x: 20, y: 352, width: 610, height: 48)
        root.addSubview(description)
        for (id, title, width) in [("visible", "Mostra", 64.0), ("name", "Elemento", 320.0), ("zone", "Posizione", 170.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title; column.width = width; table.addTableColumn(column)
        }
        table.rowHeight = 32; table.headerView?.frame.size.height = 24
        table.delegate = self; table.dataSource = self
        table.registerForDraggedTypes([dragType])
        table.setDraggingSourceOperationMask(.move, forLocal: true)
        let scroll = NSScrollView(frame: NSRect(x: 20, y: 72, width: 610, height: 276))
        scroll.borderType = .bezelBorder; scroll.hasVerticalScroller = true; scroll.documentView = table
        root.addSubview(scroll)
        let up = NSButton(title: "Sposta su", target: self, action: #selector(moveUp))
        let down = NSButton(title: "Sposta giù", target: self, action: #selector(moveDown))
        let reset = NSButton(title: "Ripristina layout", target: self, action: #selector(resetLayout))
        for (button, x, width) in [(up, 20.0, 100.0), (down, 126.0, 100.0), (reset, 466.0, 164.0)] {
            button.bezelStyle = .rounded; button.frame = NSRect(x: x, y: 22, width: width, height: 32); root.addSubview(button)
        }
        table.setAccessibilityLabel("Elementi della Touch Bar")
        window.center()
    }
    func show() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    func numberOfRows(in tableView: NSTableView) -> Int { layout.entries.count }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let entry = layout.entries[row]
        switch tableColumn?.identifier.rawValue {
        case "visible":
            let button = LayoutCheckbox(checkboxWithTitle: "", target: self, action: #selector(toggleVisible(_:)))
            button.row = row; button.state = entry.visible ? .on : .off
            button.setAccessibilityLabel("Mostra \(entry.widget.title)")
            return button
        case "zone":
            let picker = LayoutZonePicker()
            picker.addItems(withTitles: BarZone.allCases.map(\.title))
            picker.selectItem(at: BarZone.allCases.firstIndex(of: entry.zone)!)
            picker.row = row; picker.target = self; picker.action = #selector(changeZone(_:))
            picker.setAccessibilityLabel("Posizione di \(entry.widget.title)")
            return picker
        default:
            let holder = NSView()
            let label = NSTextField(labelWithString: entry.widget.title)
            label.translatesAutoresizingMaskIntoConstraints = false
            holder.addSubview(label)
            NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: holder.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: holder.centerYAnchor),
                label.trailingAnchor.constraint(lessThanOrEqualTo: holder.trailingAnchor)])
            return holder
        }
    }
    private func commit(selection: Int? = nil) {
        layout.save(); changed(layout); table.reloadData()
        if let selection { table.selectRowIndexes(IndexSet(integer: selection), byExtendingSelection: false) }
    }
    @objc private func toggleVisible(_ sender: LayoutCheckbox) {
        layout.entries[sender.row].visible = sender.state == .on; commit(selection: sender.row)
    }
    @objc private func changeZone(_ sender: LayoutZonePicker) {
        layout.entries[sender.row].zone = BarZone.allCases[sender.indexOfSelectedItem]; commit(selection: sender.row)
    }
    @objc private func moveUp() {
        let row = table.selectedRow; guard row > 0 else { return }
        layout.move(from: row, to: row - 1); commit(selection: row - 1)
    }
    @objc private func moveDown() {
        let row = table.selectedRow; guard row >= 0, row + 1 < layout.entries.count else { return }
        layout.move(from: row, to: row + 2); commit(selection: row + 1)
    }
    @objc private func resetLayout() { layout = BarLayout(); commit() }
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem(); item.setString(layout.entries[row].widget.rawValue, forType: dragType); return item
    }
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard (0...layout.entries.count).contains(row), info.draggingSource as? NSTableView === table else { return [] }
        tableView.setDropRow(row, dropOperation: .above); return .move
    }
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard (0...layout.entries.count).contains(row), info.draggingSource as? NSTableView === table,
              let id = info.draggingPasteboard.string(forType: dragType),
              let source = layout.entries.firstIndex(where: { $0.widget.rawValue == id }) else { return false }
        layout.move(from: source, to: row)
        commit(selection: row > source ? row - 1 : row); return true
    }
}
