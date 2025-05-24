//
//  SnippetViewModel.swift
//  MinimalSnippetInserter
//
//  Created by Anatoly Fedorov on 05/05/2025.
//


import Foundation
import SwiftUI

class SnippetViewModel: ObservableObject {
    @Published var snippets: [SnippetModel] = []
    @Published var selectedSnippets: Set<UUID> = []
    @Published var editingSnippet: SnippetModel?
    @Published var isEditWindowPresented = false

    init() {
        load()
    }

    func addSnippet(_ snippet: SnippetModel) {
        snippets.append(snippet)
        save()
    }

    func updateSnippet(_ updated: SnippetModel) {
        if let index = snippets.firstIndex(where: { $0.id == updated.id }) {
            snippets[index] = updated
            save()
        }
    }

    func deleteSnippet(_ snippet: SnippetModel) {
        snippets.removeAll { $0.id == snippet.id }
        selectedSnippets.remove(snippet.id)
        save()
    }

    func deleteSelectedSnippets() {
        snippets.removeAll { snippet in
            selectedSnippets.contains(snippet.id)
        }
        selectedSnippets.removeAll()
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(snippets)
            let url = getSaveURL()
            try data.write(to: url)
        } catch {
            print("❌ Ошибка сохранения: \(error)")
        }
    }

    private func load() {
        let url = getSaveURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            snippets = try JSONDecoder().decode([SnippetModel].self, from: data)
        } catch {
            print("❌ Ошибка загрузки: \(error)")
        }
    }

    private func getSaveURL() -> URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = folder.appendingPathComponent("MinimalSnippetInserter")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("snippets.json")
    }
}
