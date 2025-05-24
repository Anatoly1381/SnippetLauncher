//
//  MainAppController.swift
//  MinimalSnippetInserter
//
//  Created by Anatoly Fedorov on 07/05/2025.
//



import AppKit
import SwiftUI


class MainAppController: NSWindowController {
    private var viewModel = SnippetViewModel()

    convenience init() {
        let localViewModel = SnippetViewModel()
        let contentView = MainAppView(viewModel: localViewModel)
        let hostingView = NSHostingView(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Менеджер шаблонов"
        window.center()
        window.contentView = hostingView
        window.isReleasedWhenClosed = false

        self.init(window: window)
        self.viewModel = localViewModel
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SnippetEditorView: View {
    @State private var title: String
    @State private var content: String
    @State private var tags: String
    let isReadOnly: Bool
    let onSave: (SnippetModel?) -> Void

    init(snippet: SnippetModel, isReadOnly: Bool, onSave: @escaping (SnippetModel?) -> Void) {
        _title = State(initialValue: snippet.title)
        _content = State(initialValue: snippet.content)
        _tags = State(initialValue: snippet.tags.joined(separator: ", "))
        self.isReadOnly = isReadOnly
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Заголовок", text: $title)
                .textFieldStyle(.roundedBorder)
                .disabled(isReadOnly)

            ScrollView {
                TextEditor(text: $content)
                    .frame(minHeight: 200)
                    .border(Color.gray.opacity(0.2), width: 1)
                    .disabled(isReadOnly)
            }

            TextField("Теги (через запятую)", text: $tags)
                .textFieldStyle(.roundedBorder)
                .disabled(isReadOnly)

            if !isReadOnly {
                HStack {
                    Spacer()
                    Button("Сохранить") {
                        let tagArray = tags
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                        let updated = SnippetModel(id: UUID(), title: title, content: content, tags: tagArray)
                        onSave(updated)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

class SnippetEditorWindowController: NSWindowController {
    init(snippet: SnippetModel, isReadOnly: Bool = false, onSave: @escaping (SnippetModel?) -> Void) {
        let editorView = SnippetEditorView(snippet: snippet, isReadOnly: isReadOnly, onSave: onSave)
        let hostingView = NSHostingView(rootView: editorView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = isReadOnly ? "Просмотр шаблона" : "Редактирование шаблона"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct MainAppView: View {
    @ObservedObject var viewModel: SnippetViewModel

    var body: some View {
        VStack(spacing: 20) {
            Button("Создать") {
                let newSnippet = SnippetModel(id: UUID(), title: "", content: "", tags: [])
                let editor = SnippetEditorWindowController(snippet: newSnippet, isReadOnly: false, onSave: { updated in
                    if let snippet = updated {
                        viewModel.addSnippet(snippet)
                    }
                })
                editor.showWindow(nil)
            }

            Button("Изменить") {
                guard let selected = viewModel.snippets.first else { return }
                let editor = SnippetEditorWindowController(snippet: selected, isReadOnly: false, onSave: { updated in
                    if let snippet = updated {
                        viewModel.updateSnippet(snippet)
                    }
                })
                editor.showWindow(nil)
            }

            Button("Удалить", role: .destructive) {
                if let first = viewModel.snippets.first {
                    viewModel.deleteSnippet(first)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
