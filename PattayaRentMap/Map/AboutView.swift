//
//  AboutView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 25/04/2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)

            Text("Pattaya Rent Map")
                .font(.largeTitle.weight(.bold))

            Text("Версия \(appVersion)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
            
            Text("Приложение для управления объектами аренды на карте, с календарём бронирования, фотографиями и крутым интерфейсом 😎")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
