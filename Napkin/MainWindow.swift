import AppKit
import SwiftUI

/// Napkin's one window.
@MainActor
final class MainWindow {
    private static let autosaveName = "MainWindow"
    private static let firstSize = NSSize(width: 760, height: 560)

    private let window: NSWindow

    init() {
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.firstSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Napkin"
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 480, height: 320)
        let host = NSHostingController(rootView: ContentView())
        // Never `.preferredContentSize`: on macOS 26 it can recurse and crash.
        host.sizingOptions = []
        window.contentViewController = host
        // Setting the view controller sizes the window to its smallest size: set the first size again.
        window.setContentSize(Self.firstSize)
        if !window.setFrameUsingName(Self.autosaveName) { window.center() }
        window.setFrameAutosaveName(Self.autosaveName)
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
    }
}
