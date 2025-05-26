//
//  StatusBarTestApp.swift
//  StatusBarTest
//
//  Created by Anatoly Fedorov on 13/05/2025.
//

import SwiftUI

@main
struct StatusBarTestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
