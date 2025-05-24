//
//  MainAppController.swift
//  MinimalSnippetInserter
//
//  Created by Anatoly Fedorov on 07/05/2025.
//

import AppKit
import SwiftUI

class MainAppController: NSWindowController {
    private var viewModel: SnippetViewModel

    init(viewModel: SnippetViewModel) {
        self.viewModel = viewModel
        let contentView = MainAppView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 730, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Менеджер шаблонов"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct SnippetEditorView: View {
    @Binding var snippet: SnippetModel
    let isReadOnly: Bool
    let onSave: (SnippetModel?) -> Void
    @State private var editedContent: String
    
    init(snippet: Binding<SnippetModel>, isReadOnly: Bool, onSave: @escaping (SnippetModel?) -> Void) {
        self._snippet = snippet
        self.isReadOnly = isReadOnly
        self.onSave = onSave
        self._editedContent = State(initialValue: snippet.wrappedValue.content)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Поле заголовка
            TextField("Заголовок", text: $snippet.title)
                .textFieldStyle(.plain)
                .font(.headline)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal)
            
            // Текстовое поле
            WrappedTextView(text: $editedContent, isEditable: !isReadOnly)
                .frame(minHeight: 200)
                .padding(.horizontal)
            
            // Поле тегов
            TextField("Теги (через запятую)", text: $snippet.tagsString)
                .textFieldStyle(.plain)
                .padding(.horizontal)
            
            if !isReadOnly {
                HStack {
                    Button("Отмена", role: .cancel) {
                        onSave(nil)
                    }
                    Spacer()
                    Button("Сохранить") {
                        // Обновляем content перед сохранением
                        snippet.content = editedContent
                        let updatedSnippet = SnippetModel(
                            id: snippet.id,
                            title: snippet.title,
                            content: editedContent,
                            tags: snippet.tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        )
                        onSave(updatedSnippet)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .frame(width: 500)
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct SnippetRowView: View {
    let snippet: SnippetModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onDoubleClick: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var lastClickTime: Date?
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.title)
                    .font(.headline)
                if !snippet.tags.isEmpty {
                    Text(snippet.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected || isHovering ? Color.white.opacity(0.8) : Color.clear, lineWidth: 1)
                .background((isSelected || isHovering) ? Color.blue.opacity(0.15) : Color.clear)
        )
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .contextMenu {
            Button("Редактировать", action: onEdit)
            Button("Удалить", role: .destructive, action: onDelete)
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func handleTap() {
        let now = Date()
        if let lastClickTime = lastClickTime, now.timeIntervalSince(lastClickTime) < 0.3 {
            onDoubleClick()
            self.lastClickTime = nil
        } else {
            onSelect()
            lastClickTime = now
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.lastClickTime == now {
                    self.lastClickTime = nil
                }
            }
        }
    }
}

struct MainAppView: View {
    @ObservedObject var viewModel: SnippetViewModel
    @State private var editingContext: EditingContext?
    @State private var selectedSnippetID: UUID?
    @State private var selectedSnippetIDs: Set<UUID> = []
    @State private var shiftSelectionAnchor: UUID?
    @State private var searchText: String = ""
    
    private let searchFieldHeight: CGFloat = 14

    private struct EditingContext: Identifiable {
        let id = UUID()
        var snippet: SnippetModel
        let isNew: Bool
    }

    private var selectedSnippet: SnippetModel? {
        viewModel.snippets.first { $0.id == selectedSnippetID }
    }

    private var filteredSnippets: [SnippetModel] {
        viewModel.snippets.filter {
            searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
           VStack(spacing: 0) {
               // Измененный HStack с элементами управления
               HStack {
                   HStack(spacing: 8) {  // Внутренний HStack для поиска и кнопок
                       TextField("Поиск...", text: $searchText)
                           .textFieldStyle(.plain)
                           .padding(4)
                           .background(Color(NSColor.controlBackgroundColor))
                           .cornerRadius(6)
                           .overlay(
                               RoundedRectangle(cornerRadius: 6)
                                   .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                           )
                           .frame(width: 400, height: searchFieldHeight)  // Фиксированная ширина
                           .font(.system(size: 12))
                           .overlay(
                               HStack {
                                   Spacer()
                                   if !searchText.isEmpty {
                                       Button(action: { searchText = "" }) {
                                           Image(systemName: "xmark.circle.fill")
                                               .foregroundColor(.gray)
                                       }
                                       .buttonStyle(.plain)
                                       .padding(.trailing, 8)
                                   }
                               }
                           )

                       Button(action: createNewSnippet) {
                           Label("Создать", systemImage: "plus")
                       }
                       .buttonStyle(.borderedProminent)
                       .tint(.blue)

                       Button(action: editSelectedSnippet) {
                           Label("Изменить", systemImage: "pencil")
                       }
                       .buttonStyle(.borderedProminent)
                       .tint(.blue)
                       .disabled(selectedSnippet == nil)

                       Button(role: .destructive, action: deleteSelectedSnippet) {
                           Label("Удалить", systemImage: "trash")
                       }
                       .buttonStyle(.borderedProminent)
                       .tint(.blue)
                       .disabled(selectedSnippet == nil)
                   }
                   .padding(.leading, 8)  // Такой же отступ, как у списка
                   Spacer()  // Растягиваем до правого края
               }
               .padding(.top, 12)
               .padding(.bottom, 20)

               Divider()

               ScrollViewReader { proxy in
                   ScrollView {
                       VStack(spacing: 0) {
                           Color.clear
                               .frame(height: 1)
                               .frame(maxWidth: .infinity)
                               .contentShape(Rectangle())
                               .onTapGesture {
                                   selectedSnippetIDs.removeAll()
                                   selectedSnippetID = nil
                               }

                           LazyVStack(spacing: 0) {
                               ForEach(filteredSnippets) { snippet in
                                   SnippetRowView(
                                       snippet: snippet,
                                       isSelected: selectedSnippetIDs.contains(snippet.id),
                                       onSelect: {
                                           handleSnippetSelection(snippet)
                                       },
                                       onDoubleClick: { editingContext = EditingContext(snippet: snippet, isNew: false) },
                                       onEdit: { editingContext = EditingContext(snippet: snippet, isNew: false) },
                                       onDelete: { viewModel.deleteSnippet(snippet) }
                                   )
                               }
                           }
                           .padding(.horizontal, 8)  // Отступ такой же, как у элементов управления
                           .padding(.top, 8)
                       }
                   }
               }
           }
           .frame(minWidth: 730, minHeight: 300)
        .onAppear {
            if selectedSnippetID == nil, let first = filteredSnippets.first {
                selectedSnippetID = first.id
                selectedSnippetIDs = [first.id]
            }
        }
        .sheet(item: $editingContext) { context in
            SnippetEditorView(
                snippet: Binding(
                    get: { context.snippet },
                    set: { editingContext?.snippet = $0 }
                ),
                isReadOnly: false,
                onSave: { updated in
                    defer { editingContext = nil }
                    guard let updated = updated else { return }

                    if context.isNew {
                        viewModel.addSnippet(updated)
                    } else {
                        viewModel.updateSnippet(updated)
                    }
                    selectedSnippetID = updated.id
                }
            )
        }
    }

    private func createNewSnippet() {
        editingContext = EditingContext(
            snippet: SnippetModel(id: UUID(), title: "", content: "", tags: []),
            isNew: true
        )
    }

    private func editSelectedSnippet() {
        guard let selected = selectedSnippet else { return }
        editingContext = EditingContext(snippet: selected, isNew: false)
    }

    private func deleteSelectedSnippet() {
        if !selectedSnippetIDs.isEmpty {
            viewModel.snippets.removeAll { selectedSnippetIDs.contains($0.id) }
            selectedSnippetIDs.removeAll()
            selectedSnippetID = nil
        }
    }

    private func handleSnippetSelection(_ snippet: SnippetModel) {
        if NSEvent.modifierFlags.contains(.shift) {
            guard let anchor = shiftSelectionAnchor ?? selectedSnippetIDs.first,
                  let startIndex = filteredSnippets.firstIndex(where: { $0.id == anchor }),
                  let endIndex = filteredSnippets.firstIndex(where: { $0.id == snippet.id }) else {
                selectedSnippetIDs = [snippet.id]
                shiftSelectionAnchor = snippet.id
                selectedSnippetID = snippet.id
                return
            }

            let range = min(startIndex, endIndex)...max(startIndex, endIndex)
            selectedSnippetIDs = Set(filteredSnippets[range].map { $0.id })
        } else {
            selectedSnippetIDs = [snippet.id]
            shiftSelectionAnchor = snippet.id
        }

        selectedSnippetID = snippet.id
    }
}
