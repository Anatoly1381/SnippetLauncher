import AppKit
import SwiftUI
import IOKit.hid

final class AppDelegate: NSObject, NSApplicationDelegate {
    var mainController: MainAppController!
    private static var mainWindow: NSWindow?
    static var snippetWindow: NSWindow?
    private var lastControlPress: Date?
    private let doubleControlThreshold: TimeInterval = 0.3

    private var lastControlDownTimestamp: TimeInterval = 0
    private let controlDoubleTapThreshold: TimeInterval = 0.3

    private let sharedViewModel = SnippetViewModel.shared
    private var statusItem: NSStatusItem?
    private var statusItemMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Application did finish launching")
        // Monitor left- and right-Control key presses via Cocoa
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        setupStatusBarIcon()
        setupStatusItemMonitor()

        NotificationCenter.default.addObserver(forName: Notification.Name("closeSnippetWindow"), object: nil, queue: .main) { _ in
            print("🔻 closeSnippetWindow received — hiding window")
            AppDelegate.snippetWindow?.orderOut(nil)
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        // Detect Control key down
        if event.modifierFlags.contains(.control) {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastControlDownTimestamp <= controlDoubleTapThreshold {
                print("🔥 Double Control key tap detected via flagsChanged")
                toggleSnippetWindow()
            }
            lastControlDownTimestamp = now
        }
    }


    private func toggleSnippetWindow() {
        print("🪟 Toggling snippet window")

        // Если окно сниппетов существует
        if let window = AppDelegate.snippetWindow {
            if window.isVisible {
                print("🛑 Hiding snippet window")
                window.orderOut(nil)
            } else {
                print("🟢 Showing snippet window")
                AppDelegate.mainWindow?.orderOut(nil) // Скрываем главное окно
                window.makeKeyAndOrderFront(nil)
            }
        } else {
            // Если окно сниппетов не создано, создаём его
            print("🆕 Creating new snippet window")
            createSnippetWindow()
        }
    }

    private func createSnippetWindow() {
        print("🏗 Creating snippet window")
        let window = CustomNSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 460),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Настройки окна
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.level = .statusBar
        window.contentView = NSHostingView(rootView: SnippetPopupView().environmentObject(sharedViewModel))
        window.center()
        window.isReleasedWhenClosed = false

        // Настройки для предотвращения активации
        window.styleMask.update(with: .nonactivatingPanel)
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        window.level = .statusBar

        AppDelegate.snippetWindow = window
        print("🪟 Snippet window created")

        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            if window.isVisible {
                print("🖱 Click outside detected — hiding snippet window")
                window.orderOut(nil)
            }
        }

        // Показываем окно без активации
        window.orderFrontRegardless()
    }

    private func setupStatusBarIcon() {
        print("📌 Setting up status bar icon")
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        }

        if let button = statusItem?.button {
            print("🖱 Configuring status bar button")
            button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "Snippets")
            button.action = #selector(handleStatusBarClick)
            button.target = self
        } else {
            print("❌ Failed to configure status bar button")
        }
    }

    private func setupStatusItemMonitor() {
        print("👀 Setting up status item monitor")
        statusItemMonitor = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔍 Checking status item after window resign")
            if self?.statusItem == nil {
                print("⚠️ Status item missing, recreating")
                self?.setupStatusBarIcon()
            }
        }
    }

    @objc private func handleStatusBarClick() {
        print("🖱 Status bar icon clicked")

        // Активируем приложение, если оно не активно
        if !NSApp.isActive {
            print("🔄 Activating application")
            NSApp.activate(ignoringOtherApps: true)
        }

        // Если окно сниппетов видимо, скрываем его
        if let snippetWindow = AppDelegate.snippetWindow, snippetWindow.isVisible {
            print("🔻 Hiding snippet window before opening main window")
            snippetWindow.orderOut(nil)
        }

        // Проверяем состояние главного окна
        if let mainWindow = AppDelegate.mainWindow {
            if mainWindow.isVisible {
                print("🔄 Main window already visible, bringing to front")
                mainWindow.makeKeyAndOrderFront(nil)
            } else {
                print("🖥 Showing existing main window")
                mainWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            print("🆕 Creating new main window")
            showMainAppWindow()
        }
    }

    private func showMainAppWindow() {
        // Гарантированно скрываем окно сниппетов
        AppDelegate.snippetWindow?.orderOut(nil)

        if let mainWindow = AppDelegate.mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            mainController = MainAppController(viewModel: sharedViewModel)
            AppDelegate.mainWindow = mainController.window
            mainController.showWindow(self)
            NSApp.activate(ignoringOtherApps: true) // Активируем приложение
        }
    }

    deinit {
        if let monitor = statusItemMonitor {
            NotificationCenter.default.removeObserver(monitor)
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        print("❌ Window will close: \(window)")
    }
}
