//
//  MinimalSnippetInserter.swift
//  MinimalSnippetInserter
//
//  Created by Anatoly Fedorov on 01/05/2025.
//

import SwiftUI
import AppKit
import HotKey


struct Snippet: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var tags: [String] = []
}

class SnippetStore: ObservableObject {
    @Published var snippets: [Snippet] = []

    private let saveURL: URL = {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = folder.appendingPathComponent("MinimalSnippetInserter")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("snippets.json")
    }()

    init() {
        load()
    }

    func addTestSnippet() {
        let snippet = Snippet(id: UUID(), title: "Пример", content: "Примерный текст")
        snippets.append(snippet)
        save()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(snippets)
            try data.write(to: saveURL)
        } catch {
            print("❌ Не удалось сохранить: \(error)")
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            snippets = try JSONDecoder().decode([Snippet].self, from: data)
        } catch {
            print("❌ Не удалось загрузить: \(error)")
        }
    }
}

struct ContentView: View {
    @State private var hotKey: HotKey?
    @State private var hotKeys: [HotKey] = []
    @State private var globalHotKey: HotKey?
    @StateObject private var store = SnippetStore()
    @State private var hoveredID: UUID?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(store.snippets.enumerated()), id: \.element.id) { index, snippet in
                                Button(action: {
                                    insertText(snippet.content)
                                }) {
                                    ZStack(alignment: .leading) {
                                        if hoveredID == snippet.id {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.purple.opacity(0.8))
                                                .padding(.horizontal, 4)
                                        }

                                        HStack {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(Color(red: 0.60, green: 0.07, blue: 0.80))
                                                .shadow(color: Color.purple.opacity(0.6), radius: 4, x: 0, y: 2)
                                                .shadow(color: Color.white.opacity(0.3), radius: 1, x: -1, y: -1)
                                                .padding(.leading, 8)

                                            Text(snippet.title)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(hoveredID == snippet.id ? .white : .primary)
                                                .padding(.leading, 2)
                                                .padding(.vertical, 2)

                                            Spacer()

                                            if index < 9 {
                                                Text("⌘\(index + 1)")
                                                    .font(.body)
                                                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.60, green: 0.07, blue: 0.80))
                                                    .padding(.trailing, 15)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                        .padding(.leading, 10)
                                    }
                                }
                                .buttonStyle(.plain)
                                .onHover { hovering in
                                    hoveredID = hovering ? snippet.id : nil
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .frame(width: 300)
                    .padding(.top, 12)
                }

                Divider()

                VStack(alignment: .leading) {
                    if let hoveredID = hoveredID, let snippet = store.snippets.first(where: { $0.id == hoveredID }) {
                        Text(snippet.content)
                            .font(.body)
                            .padding(.leading, 36)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.top, 12)
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 12)
            }
        }
        .frame(width: 750, height: 460)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 10)
        )
        .padding()
        .onAppear {
            hotKey = HotKey(key: .one, modifiers: [.command])
            hotKey?.keyDownHandler = {
                if let first = store.snippets.first {
                    insertText(first.content)
                }
            }
            
            hotKeys = (0..<min(9, store.snippets.count)).map { index in
                let key = Key(string: "\(index + 1)") ?? .one
                let hk = HotKey(key: key, modifiers: [.command])
                hk.keyDownHandler = {
                    let snippet = store.snippets[index]
                    insertText(snippet.content)
                }
                return hk
            }
            
            globalHotKey = HotKey(key: .space, modifiers: [.command, .shift])
            globalHotKey?.keyDownHandler = {
                NSApp.activate(ignoringOtherApps: true)
                NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
            }
        }
    }

    func insertText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        NSApplication.shared.hide(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let src = CGEventSource(stateID: .combinedSessionState)
            let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: true)
            let vDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
            let vUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
            let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: false)

            cmdDown?.flags = .maskCommand
            vDown?.flags = .maskCommand
            vUp?.flags = .maskCommand

            cmdDown?.post(tap: .cghidEventTap)
            vDown?.post(tap: .cghidEventTap)
            vUp?.post(tap: .cghidEventTap)
            cmdUp?.post(tap: .cghidEventTap)
        }
    }
}

// @main
// struct MinimalSnippetInserterApp: App {
//     var body: some Scene {
//         WindowGroup {
//             EmptyView()
//         }
//     }
// }
