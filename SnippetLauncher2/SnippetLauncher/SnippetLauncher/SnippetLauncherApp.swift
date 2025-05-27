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
    @StateObject var viewModel = SnippetViewModel.shared

    var body: some Scene {
        // The Settings scene automatically gets a "Settings…" menu entry
        Settings {
            SettingsView()
        }
    }
}
