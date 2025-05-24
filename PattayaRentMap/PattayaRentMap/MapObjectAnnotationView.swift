//
//  MapObjectAnnotationView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 17/04/2025.
//

import SwiftUICore

struct MapObjectAnnotationView: View {
    let object: MapObject

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 50, height: 35)
                .cornerRadius(4)

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1))

                Image(systemName: "house.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(object.status == .available ? .green : .red)
            }
        }
    }
}
