//
//  SnippetLauncherApp.swift
//  SnippetLauncher
//
//  Created by Anatoly Fedorov on 07/05/2025.
//
import AppKit
import Foundation
import SwiftUI
import Combine

@main
struct SnippetLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
