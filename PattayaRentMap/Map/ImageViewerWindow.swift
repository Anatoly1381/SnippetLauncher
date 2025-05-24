//
//  ImageViewerWindow.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 24/04/2025.
//

import SwiftUI
import AppKit

struct ImageViewerWindow: View {
    let images: [NSImage]
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0

    init(images: [NSImage], startIndex: Int = 0) {
        self.images = images
        self._currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                ZoomableImageView(image: images[currentIndex])
                    

                Spacer()

                Text("\(currentIndex + 1) из \(images.count)")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption2)
                    .padding(.bottom, 8)

                HStack(spacing: 20) {
                    Button {
                        withAnimation {
                            currentIndex = max(0, currentIndex - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(currentIndex == 0 ? 0.1 : 0.3)))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentIndex == 0)

                    Button {
                        withAnimation {
                            currentIndex = min(images.count - 1, currentIndex + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(currentIndex == images.count - 1 ? 0.1 : 0.3)))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentIndex == images.count - 1)
                }
                .padding(.bottom, 20)
            }
        }
    }
}
