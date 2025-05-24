
import AppKit
import SwiftUI
import HotKey


final class CustomNSWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    // Добавьте этот критически важный метод
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Пропускаем Command+V для обработки в NSTextView
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "v" {
            return false
        }
        return super.performKeyEquivalent(with: event)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Статические ссылки для глобального доступа
    private static var mainWindow: NSWindow?
    private static var snippetWindow: NSWindow?
    
    private var hotKey: HotKey?
    private var isHandlingHotKey = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        showMainAppWindow()
        setupGlobalHotKey()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }


    private func setupGlobalHotKey() {
        hotKey = HotKey(key: .space, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            guard let self = self else { return }
            self.toggleSnippetWindow()
        }
    }

    private func toggleSnippetWindow() {
        guard !isHandlingHotKey else { return }
        isHandlingHotKey = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Скрываем главное окно, если оно видно
            if let mainWindow = AppDelegate.mainWindow, mainWindow.isVisible {
                mainWindow.orderOut(nil)
            }

            if let window = AppDelegate.snippetWindow {
                if window.isVisible {
                    window.orderOut(nil)
                } else {
                    window.orderFrontRegardless()
                    // NSApp.activate(ignoringOtherApps: true)
                }
            } else {
                self.createSnippetWindow()
            }

            self.isHandlingHotKey = false
        }
    }
    
    private func createSnippetWindow() {
        let window = CustomNSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 460),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView], // Измените стиль
            backing: .buffered,
            defer: false
        )
        
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        // window.level = .floating
        window.delegate = self
        window.contentView = NSHostingView(rootView: ContentView())
        window.center()
        window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = false
            window.acceptsMouseMovedEvents = true
            window.collectionBehavior = [.managed, .fullScreenAuxiliary]
        
        AppDelegate.snippetWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    private func showMainAppWindow() {
        let mainController = MainAppController()
        AppDelegate.mainWindow = mainController.window
        mainController.showWindow(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if window == AppDelegate.mainWindow {
            AppDelegate.mainWindow = nil
        } else if window == AppDelegate.snippetWindow {
            AppDelegate.snippetWindow = nil
            
            // Показываем главное окно, если оно было скрыто
            if let mainWindow = AppDelegate.mainWindow {
                mainWindow.makeKeyAndOrderFront(nil)
            }
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        if window == AppDelegate.snippetWindow {
            window.orderOut(nil)
        }
    }
}
