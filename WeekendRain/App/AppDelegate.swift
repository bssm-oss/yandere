import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = MainWindowController()
        mainWindowController = controller
        controller.showWindow(nil)
        controller.presentMainWindow()
        NSApp.activate(ignoringOtherApps: true)
        stabilizeWindowPlacement(for: controller)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    private func stabilizeWindowPlacement(for controller: MainWindowController) {
        for delay in [0.05, 0.25, 0.75] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                controller.presentMainWindow()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
