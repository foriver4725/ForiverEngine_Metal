import Cocoa

@main
@MainActor
struct Main_Internal {
    static func main() {
        let app = NSApplication.shared
        let delegate = Delegate()

        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
