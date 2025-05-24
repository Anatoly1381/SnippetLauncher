//
//  WindowManager.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 21/04/2025.
//
import SwiftUI
import AppKit

// Хранилище активных окон
var windowControllers: [NSWindowController] = []

// Открытие окна с карточкой объекта
func openWindowFor<V: View>(_ view: V, title: String = "Объект аренды") {
    let hostingController = NSHostingController(rootView: view)
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
        styleMask: [.titled, .closable, .resizable, .miniaturizable],
        backing: .buffered,
        defer: false
    )
    window.title = title
    window.center()
    window.contentView = hostingController.view

    let controller = NSWindowController(window: window)
    controller.shouldCascadeWindows = true
    controller.showWindow(nil)

    windowControllers.append(controller)

    NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
        windowControllers.removeAll { $0 == controller }
    }
}

// Открытие отдельного окна для просмотра фото
func openImageWindow(images: [NSImage], startIndex: Int = 0) {
    let hostingController = NSHostingController(
        rootView: ImageViewerWindow(images: images, startIndex: startIndex)
    )
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered,
        defer: false
    )
    window.title = "Просмотр изображения"
    window.center()
    window.contentView = hostingController.view

    let controller = NSWindowController(window: window)
    controller.shouldCascadeWindows = true
    controller.showWindow(nil)

    windowControllers.append(controller)

    NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
        windowControllers.removeAll { $0 == controller }
    }
}
