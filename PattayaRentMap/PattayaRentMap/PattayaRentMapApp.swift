//
//  PattayaRentMapApp.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 26/3/2568 BE.
//

import SwiftUI

@main
struct PattayaRentMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
class PhotoViewerState: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var images: [NSImage] = []
    @Published var currentIndex: Int = 0
    
    func show(images: [NSImage], startingAt index: Int = 0) {
        self.images = images
        self.currentIndex = index
        self.isPresented = true
    }
}
