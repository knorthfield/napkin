import SwiftUI

@main
struct NapkinApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: NoteStore?
    private var window: MainWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests run inside the app: do not show the window.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        let store = NoteStore()
        let window = MainWindow(store: store)
        window.show()
        self.store = store
        self.window = window
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        store?.load()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
