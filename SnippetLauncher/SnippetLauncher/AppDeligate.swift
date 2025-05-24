import AppKit
import SwiftUI
import HotKey

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var mainWindow: NSWindow?
    static var snippetWindow: CustomNSWindow?
    
    private let sharedViewModel = SnippetViewModel.shared
    private var globalHotKey: HotKey?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        setupGlobalHotKey()
        setupStatusBarIcon()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("Application should handle reopen")
        return false
    }

    private func setupGlobalHotKey() {
        print("Setting up global hotkey")
        globalHotKey = HotKey(key: .space, modifiers: [.command, .shift])
        globalHotKey?.keyDownHandler = { [weak self] in
            print("Global hotkey triggered")
            self?.toggleSnippetWindow()
        }
    }

    private func toggleSnippetWindow() {
        print("Toggling snippet window")
        if let window = AppDelegate.snippetWindow {
            if window.isVisible {
                print("Snippet window is visible, hiding it")
                window.orderOut(nil)
            } else {
                print("Snippet window is not visible, showing it")
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            print("Snippet window does not exist, creating it")
            createSnippetWindow()
        }
    }
    
    private func createSnippetWindow() {
        print("Creating snippet window")
        let window = CustomNSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 460),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.level = .floating
        window.contentView = NSHostingView(rootView: SnippetPopupView().environmentObject(sharedViewModel))
        window.center()
        window.isReleasedWhenClosed = false

        AppDelegate.snippetWindow = window
        print("Snippet window created")
        window.makeKeyAndOrderFront(nil)
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func showMainAppWindow() {
        print("Showing main app window")
        if let window = AppDelegate.mainWindow {
            print("Main app window already exists, bringing it to front")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            print("Main app window does not exist, creating it")
            let mainController = MainAppController(viewModel: sharedViewModel)
            AppDelegate.mainWindow = mainController.window
            mainController.showWindow(self)
        }
    }
    
    private func setupStatusBarIcon() {
        print("Setting up status bar icon")
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        }
        
        if let button = statusItem?.button {
            print("Configuring status bar button")
            button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "Snippets")
            button.action = #selector(showMainWindowFromStatusBar)
            button.target = self
        }
    }

    @objc private func showMainWindowFromStatusBar() {
        print("Status bar icon clicked")
        showMainAppWindow()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        print("Window will close: \(window)")

        if window == AppDelegate.mainWindow {
            print("Main app window is closing")
            AppDelegate.mainWindow = nil
        } else if window == AppDelegate.snippetWindow {
            print("Snippet window is closing")
            AppDelegate.snippetWindow = nil
        }
    }
}

extension AppDelegate {
    func applicationDidBecomeActive(_ notification: Notification) {
        print("Application did become active")
        if statusItem == nil {
            print("Status bar icon is missing, recreating it")
            setupStatusBarIcon()
        }
    }
}
