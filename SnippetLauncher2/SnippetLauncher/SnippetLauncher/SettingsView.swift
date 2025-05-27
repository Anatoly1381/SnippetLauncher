import SwiftUI
import AppKit

extension Color {
    /// Convert Color to hex string "#RRGGBB" or "#AARRGGBB" if transparency present.
    func toHex() -> String {
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return "#FFFFFF"
        }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        let a = Int(rgbColor.alphaComponent * 255)

        if a < 255 {
            return String(format: "#%02X%02X%02X%02X", a, r, g, b)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }

    /// System default background color (adaptable to theme)
    static var systemDefaultBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }
}

struct SettingsView: View {
    @AppStorage("backgroundColorHex") private var bgColorHex: String = "#FFFFFF"
    @Environment(\.colorScheme) private var colorScheme // Access current theme (light/dark)

    /// Generate a richer palette including grays and Hue×Saturation grid.
    private var paletteHex: [String] {
        var arr: [String] = []

        // 1) Grayscale at clear distinct levels
        let grayLevels: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
        for level in grayLevels {
            let gray = Color(white: level)
            arr.append(gray.toHex())
        }

        // 2) Beige and brown accents (hue 0.05 to 0.15)
        let brownHues = stride(from: 0.05, through: 0.15, by: 0.02)
        for hue in brownHues {
            let c = Color(hue: hue, saturation: 0.7, brightness: 0.75)
            arr.append(c.toHex())
        }

        // 3) Hue x Saturation grid
        let hueSteps = 36           // 10° increments
        let satSteps = 10           // 10% increments
        for satIndex in 1..<satSteps {
            let sat = Double(satIndex) / Double(satSteps - 1)
            for hueIndex in 0..<hueSteps {
                let hue = Double(hueIndex) / Double(hueSteps - 1)
                let color = Color(hue: hue, saturation: sat, brightness: 0.8)
                arr.append(color.toHex())
            }
        }
        return arr
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Background Color")
                .font(.headline)

            ScrollView {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 12)
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(paletteHex.enumerated()), id: \.offset) { _, hex in
                        Rectangle()
                            .fill(Color(hex: hex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.primary.opacity(bgColorHex == hex ? 1 : 0), lineWidth: 2)
                            )
                            .onTapGesture {
                                bgColorHex = hex
                            }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 300)

            HStack {
                Spacer()
                Button(action: {
                    // Reset to default system background color
                    bgColorHex = Color.systemDefaultBackground.toHex()
                }) {
                    Text("Reset")
                }
                .keyboardShortcut("R", modifiers: [.command])
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(width: 500, height: 400)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(hex: bgColorHex)
                .opacity(colorScheme == .dark ? 0.9 : 1.0) // Adjust opacity for dark mode
        )
    }
}
