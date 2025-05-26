//
//  AppDelegate.swift
//  StatusBarTest
//
//  Created by Anatoly Fedorov on 13/05/2025.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popupWindow: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Test")
            button.action = #selector(togglePopup)
            button.target = self
        }

        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                            styleMask: [.titled, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.title = "Вставка"
        panel.center()

        let button = NSButton(title: "Вставить", target: self, action: #selector(insertText))
        button.frame = NSRect(x: 50, y: 30, width: 100, height: 40)
        panel.contentView?.addSubview(button)

        popupWindow = panel
    }

    @objc func togglePopup() {
        if let window = popupWindow {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    @objc func insertText() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("Тестовая вставка", forType: .string)

        if let previousApp = NSWorkspace.shared.frontmostApplication {
            previousApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .combinedSessionState)
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            cmdDown?.flags = .maskCommand
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            vDown?.flags = .maskCommand
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            vUp?.flags = .maskCommand
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

            cmdDown?.post(tap: .cghidEventTap)
            vDown?.post(tap: .cghidEventTap)
            vUp?.post(tap: .cghidEventTap)
            cmdUp?.post(tap: .cghidEventTap)
        }
    }
}
