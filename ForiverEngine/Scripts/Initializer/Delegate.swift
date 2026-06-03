import Cocoa

@MainActor
class Delegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var viewController: ViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        viewController = ViewController()

        window = Window(
            contentRect: WindowHelper.windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "ForiverEngine"
        window.center()
        window.contentViewController = viewController
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewController.saveWorld()
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        true
    }
}
