//
//  CustomNSWindow.swift
//  SnippetLauncher
//
//  Created by Anatoly Fedorov on 13/05/2025.
//

import AppKit

final class CustomNSWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var acceptsFirstResponder: Bool { true }
}
