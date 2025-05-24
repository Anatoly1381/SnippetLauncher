//
//  ZoomableImageView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 24/04/2025.
//

import SwiftUI
import AppKit

struct ZoomableImageView: View {
    let image: NSImage
    @State private var scale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut) {
                        if scale > 1 {
                            scale = 1
                        } else {
                            scale = 2.5
                        }
                    }
                }
        }
    }
}
