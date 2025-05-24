import SwiftUI
import MapKit
import AppKit

struct PhotoFileManager {
    private let directoryName = "Photos"

    private var photosDirectoryURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(directoryName)
    }

    init() {
        createPhotosDirectoryIfNeeded()
    }

    private func createPhotosDirectoryIfNeeded() {
        guard let photosURL = photosDirectoryURL else { return }
        if !FileManager.default.fileExists(atPath: photosURL.path) {
            try? FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
        }
    }

    func savePhoto(from url: URL) -> String? {
        guard let photosURL = photosDirectoryURL else { return nil }
        let uniqueName = UUID().uuidString + "." + url.pathExtension
        let destinationURL = photosURL.appendingPathComponent(uniqueName)

        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Ошибка при сохранении изображения: \(error.localizedDescription)")
            return nil
        }
    }

    func loadPhoto(from path: String) -> NSImage? {
        let url = URL(fileURLWithPath: path)
        return NSImage(contentsOf: url)
    }

    func deletePhoto(at path: String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            print("Ошибка при удалении изображения: \(error.localizedDescription)")
        }
        
    }
}
// MARK: - PhotoFileManager Extension
extension PhotoFileManager {
    func savePhoto(from image: NSImage) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            return nil
        }

        let filename = UUID().uuidString + ".jpg"
        guard let photosURL = photosDirectoryURL else { return nil }
        let url = photosURL.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            return url.path
        } catch {
            print("Ошибка при сохранении NSImage: \(error)")
            return nil
        }
    }
}
func loadPhoto(from path: String) -> NSImage? {
    let url = URL(fileURLWithPath: path)
    guard let image = NSImage(contentsOf: url) else {
        print("❌ Failed to load image at path: \(path)")
        return nil
    }
    print("✅ Loaded image \(path), size: \(image.size)")
    return image
}
