import Cocoa

//@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let vc = ViewController()

        window = EscWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1600, height: 900),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "ForiverEngine"
        window.center()
        window.contentViewController = vc
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
