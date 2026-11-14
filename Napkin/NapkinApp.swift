import SwiftUI

@main
struct NapkinApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            SettingsView(rates: appDelegate.rates)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") { appDelegate.store?.addNote() }
                    .keyboardShortcut("n")
            }
            CommandGroup(after: .pasteboard) {
                // The editor with the caret gets the command.
                Button("Copy Result") { NSApp.sendAction(#selector(EditorView.copyResult(_:)), to: nil, from: nil) }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let rates = CurrencyRates()
    private(set) var store: NoteStore?
    private var window: MainWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests run inside the app: do not show the window.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        let store = NoteStore()
        let window = MainWindow(store: store, rates: rates)
        window.show()
        self.store = store
        self.window = window
        Task { await rates.refreshIfOld() }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard let store else { return }
        store.load()
        Task { await rates.refreshIfOld() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
