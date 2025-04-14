//
//  SceneDelegate.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 11/04/2025.
//

import SwiftUI

@main
struct PattayaRentMapApp: App {
    @StateObject private var viewModel = ApartmentViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
