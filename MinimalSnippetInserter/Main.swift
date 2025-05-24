import AppKit

@main
struct MinimalSnippetInserterApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = AppDelegate()
        app.delegate = delegate
        _ = delegate
        app.run()
    }
}
