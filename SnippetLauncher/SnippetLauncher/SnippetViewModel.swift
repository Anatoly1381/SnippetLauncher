//
//  SnippetViewModel.swift
//  MinimalSnippetInserter
//
//  Created by Anatoly Fedorov on 07/05/2025.
//

import Foundation
import SwiftUI

class SnippetViewModel: ObservableObject {
    static let shared = SnippetViewModel()
    @Published var snippets: [SnippetModel] = [] {
        didSet { save() }
    }
    @Published var selectedSnippets: Set<UUID> = []
    
    private let saveURL: URL = {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = folder.appendingPathComponent("MinimalSnippetInserter")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("snippets.json")
    }()

    private init() { load() }

    func addSnippet(_ snippet: SnippetModel) {
        guard !snippets.contains(where: { $0.id == snippet.id }) else { return }
        snippets.append(snippet)
    }

    func updateSnippet(_ updated: SnippetModel) {
        if let index = snippets.firstIndex(where: { $0.id == updated.id }) {
            snippets[index] = updated
        }
    }

    func deleteSnippet(_ snippet: SnippetModel) {
        snippets.removeAll { $0.id == snippet.id }
        selectedSnippets.remove(snippet.id)
    }

    func deleteSelectedSnippets() {
        snippets.removeAll { selectedSnippets.contains($0.id) }
        selectedSnippets.removeAll()
    }

     func save() {
        print("💾 Сохраняем шаблоны: \(snippets.map { $0.title })")
        do {
            let data = try JSONEncoder().encode(snippets)
            try data.write(to: saveURL)
        } catch {
            print("❌ Ошибка сохранения: \(error)")
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            snippets = try JSONDecoder().decode([SnippetModel].self, from: data)
        } catch {
            print("❌ Ошибка загрузки: \(error)")
        }
    }
}
