//
//  MainAppController.swift
//  MinimalSnippetInserter
//
//  Created by Anatoly Fedorov on 07/05/2025.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

class MainAppController: NSWindowController {
    private var viewModel: SnippetViewModel

    init(viewModel: SnippetViewModel) {
        self.viewModel = viewModel
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        // Set initial title from the system locale bundle
        let sysLocale = Locale.current.language.languageCode?.identifier ?? "en"
        if let path = Bundle.main.path(forResource: sysLocale, ofType: "lproj"),
           let sysBundle = Bundle(path: path) {
            window.title = sysBundle.localizedString(forKey: "window_title", value: nil, table: nil)
        }
        let contentView = MainAppView(viewModel: viewModel) { newLocale in
            // Load localized title from the selected locale bundle
            if let path = Bundle.main.path(forResource: newLocale, ofType: "lproj"),
               let localeBundle = Bundle(path: path) {
                let title = localeBundle.localizedString(forKey: "window_title", value: nil, table: nil)
                window.title = title
            }
        }
        let hostingView = NSHostingView(rootView: contentView)
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
    @State private var originalContent: String
    @State private var isContentDirty = false

    init(snippet: Binding<SnippetModel>, isReadOnly: Bool, onSave: @escaping (SnippetModel?) -> Void) {
        self._snippet = snippet
        self.isReadOnly = isReadOnly
        self.onSave = onSave
        self._editedContent = State(initialValue: snippet.wrappedValue.content)
        self._originalContent = State(initialValue: snippet.wrappedValue.content)
    }

    var body: some View {
        ZStack {
            // Entire sheet background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            // Editor card
            VStack(alignment: .leading, spacing: 16) {
                // Title field
                TextField(
                    LocalizedStringKey("editor_title_placeholder"),
                    text: $snippet.title
                )
                .textFieldStyle(.plain)
                .font(.headline)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )

                // Text view
                WrappedTextView(text: $editedContent, isEditable: !isReadOnly)
                    .frame(minHeight: 200)
                    .background(Color(NSColor.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )

                // Tags field
                TextField(
                    LocalizedStringKey("editor_tags_placeholder"),
                    text: $snippet.tagsString
                )
                .textFieldStyle(.plain)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )

                if !isReadOnly {
                    HStack(spacing: 8) {
                        Spacer()
                        Button(action: { onSave(nil) }) {
                            Text(LocalizedStringKey("button_cancel"))
                                .frame(maxWidth: .infinity)
                        }
                        .frame(width: 85, height: 44)
                        .buttonStyle(.bordered)

                        Button(action: {
                            snippet.content = editedContent
                            let updatedSnippet = SnippetModel(
                                id: snippet.id,
                                title: snippet.title,
                                content: editedContent,
                                tags: snippet.tagsString
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespaces) }
                            )
                            onSave(updatedSnippet)
                        }) {
                            Text(LocalizedStringKey("button_save"))
                                .frame(maxWidth: .infinity)
                        }
                        .frame(width: 85, height: 44)
                        .buttonStyle(.bordered)
                        .disabled(!isContentDirty)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .frame(maxWidth: 600)
        }
        .onChange(of: editedContent) {
            // editedContent уже обновлён
            if originalContent.isEmpty {
                isContentDirty = !editedContent.isEmpty
            } else {
                isContentDirty = editedContent != originalContent
            }
        }
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
                if isHovering {
                    Text(snippet.content)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3) // allow up to 3 lines, adjust as needed
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected || isHovering ? Color.blue.opacity(0.15) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected || isHovering ? Color.white.opacity(0.8) : Color.clear, lineWidth: 1)
                )
        )
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .contextMenu {
            Button(LocalizedStringKey("menu_edit"), action: onEdit)
            Button(LocalizedStringKey("menu_delete"), role: .destructive, action: onDelete)
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            let provider = NSItemProvider(object: snippet.content as NSString)
            provider.registerDataRepresentation(
                forTypeIdentifier: UTType.data.identifier,
                visibility: .all
            ) { completion in
                let data = snippet.id.uuidString.data(using: .utf8)
                completion(data, nil)
                return nil
            }
            return provider
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
    let onLocaleChange: (String) -> Void
    @State private var editingContext: EditingContext?
    @State private var selectedSnippetID: UUID?
    @State private var selectedSnippetIDs: Set<UUID> = []
    @State private var shiftSelectionAnchor: UUID?
    @State private var searchText: String = ""
    @State private var localeIdentifier: String = Locale.current.language.languageCode?.identifier ?? "en"

    private var displayLocaleCode: String {
        switch localeIdentifier {
        case "pt-PT": return "PT"
        case "pt-BR": return "BR"
        case "zh-Hans": return "ZH"
        default: return localeIdentifier.uppercased()
        }
    }

    @AppStorage("backgroundColorHex") private var bgColorHex: String = "#FFFFFF"
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        // Тримим hex и приводим к единому регистру
        let hex = bgColorHex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex == "#FFFFFF" {
            // системный динамический цвет окна
            return Color(NSColor.windowBackgroundColor)
        }
        // для кастомного цвета тоже возвращаем динамический цвет на основе NSColor
        let nsColor = NSColor(named: hex) ?? NSColor.windowBackgroundColor
        return Color(nsColor)
    }

    // Константы для размеров и отступов
    private let searchFieldHeight: CGFloat = 14
    private let buttonWidth: CGFloat = 80
    private let searchFieldWidth: CGFloat = 300
    private let elementSpacing: CGFloat = 8
    private let horizontalPadding: CGFloat = 8
    private let verticalPadding: CGFloat = 8

    init(viewModel: SnippetViewModel, onLocaleChange: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onLocaleChange = onLocaleChange
    }

    private struct EditingContext: Identifiable {
        let id = UUID()
        var snippet: SnippetModel
        let isNew: Bool
    }

    private var selectedSnippet: SnippetModel? {
        viewModel.snippets.first { $0.id == selectedSnippetID }
    }

    private var filteredSnippets: [SnippetModel] {
        guard !searchText.isEmpty else { return viewModel.snippets }
        let query = searchText.lowercased()
        return viewModel.snippets.filter { snippet in
            // Search within the full title (including spaces)
            snippet.title.lowercased().contains(query)
            // Optionally also search within tags
            || snippet.tags.joined(separator: " ").lowercased().contains(query)
        }
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            VStack(spacing: 0) {
            HStack(alignment: .center, spacing: elementSpacing) {
                // Поле поиска
                TextField(LocalizedStringKey("search_placeholder"), text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: searchFieldWidth, height: searchFieldHeight)
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

                // Кнопка создания
                Button(action: createNewSnippet) {
                    Label {
                        Text(LocalizedStringKey("button_create"))
                    } icon: {
                        Image(systemName: "plus")
                    }
                    .frame(maxWidth: .infinity) // Центрируем текст внутри кнопки
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 100) // Устанавливаем фиксированную ширину

                // Кнопка редактирования
                Button(action: editSelectedSnippet) {
                    Label {
                        Text(LocalizedStringKey("button_edit"))
                    } icon: {
                        Image(systemName: "pencil")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 105)
                .disabled(selectedSnippet == nil)

                // Кнопка удаления
                Button(role: .destructive, action: deleteSelectedSnippet) {
                    Label {
                        Text(LocalizedStringKey("button_delete"))
                    } icon: {
                        Image(systemName: "trash")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 102)
                .disabled(selectedSnippet == nil)

                // Выбор языка
                Menu {
                    Button(action: { localeIdentifier = "en" }) {
                        Label("🇬🇧", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "ru" }) {
                        Label("🇷🇺", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "fr" }) {
                        Label("🇫🇷", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "de" }) {
                        Label("🇩🇪", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "es" }) {
                        Label("🇪🇸", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "it" }) {
                        Label("🇮🇹", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "pt-BR" }) {
                        Label("🇧🇷", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "pt-PT" }) {
                        Label("🇵🇹", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "zh-Hans" }) {
                        Label("🇨🇳", systemImage: "")
                    }
                    Button(action: { localeIdentifier = "th" }) {
                        Label("🇹🇭", systemImage: "")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.blue.opacity(1))
                            .font(.title2)
                        Text(displayLocaleCode)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .menuStyle(.borderlessButton)

                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            
            Divider()

            if filteredSnippets.isEmpty {
                Text(LocalizedStringKey("empty_state"))
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
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
                                    .onDrop(
                                        of: [UTType.data.identifier, UTType.plainText.identifier],
                                        delegate: SnippetDropDelegate(
                                            targetID: snippet.id,
                                            viewModel: viewModel
                                        )
                                    )
                                }
                            }
                            .padding(.bottom, 16)
                            .padding(.horizontal, 8)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedSnippetIDs.removeAll()
            selectedSnippetID = nil
        }
        .frame(minWidth: 730, minHeight: 320)
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
            .environment(\.locale, Locale(identifier: localeIdentifier))
            .background(Color(NSColor.windowBackgroundColor))
        }
        .animation(.easeInOut, value: editingContext != nil)
        .onChange(of: localeIdentifier) { oldValue, newValue in
            onLocaleChange(newValue)
        }
        .environment(\.locale, Locale(identifier: localeIdentifier))
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
            // Удаляем выбранные сниппеты
            viewModel.snippets.removeAll { selectedSnippetIDs.contains($0.id) }
            
            // Принудительное обновление UI
            viewModel.objectWillChange.send()
            
            // Сбрасываем выбранные сниппеты
            selectedSnippetIDs.removeAll()
            selectedSnippetID = nil
            
            // Обновляем список после удаления
            if let first = filteredSnippets.first {
                selectedSnippetID = first.id
                selectedSnippetIDs = [first.id]
            }
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

private struct SnippetDropDelegate: SwiftUI.DropDelegate {
    let targetID: UUID
    @ObservedObject var viewModel: SnippetViewModel

    func dropUpdated(info: DropInfo) -> DropProposal? {
        if info.hasItemsConforming(to: [UTType.data.identifier]) {
            return DropProposal(operation: .move)
        }
        if info.hasItemsConforming(to: [UTType.plainText.identifier]) {
            return DropProposal(operation: .copy)
        }
        return nil
    }

    func performDrop(info: DropInfo) -> Bool {
        if let provider = info.itemProviders(for: [UTType.data.identifier]).first {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) { data, _ in
                guard let data = data,
                      let idString = String(data: data, encoding: .utf8),
                      let draggedID = UUID(uuidString: idString),
                      let fromIndex = viewModel.snippets.firstIndex(where: { $0.id == draggedID }),
                      let toIndex = viewModel.snippets.firstIndex(where: { $0.id == targetID })
                else { return }
                DispatchQueue.main.async {
                    viewModel.snippets.swapAt(fromIndex, toIndex)
                }
            }
            return true
        }
        if let provider = info.itemProviders(for: [UTType.plainText.identifier]).first {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                guard let str = item as? String else { return }
                DispatchQueue.main.async {
                    // Bring snippet popup to front so paste is directed correctly
                    if let win = AppDelegate.snippetWindow {
                        win.makeKeyAndOrderFront(nil)
                    } else {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(str, forType: .string)
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
            }
            return true
        }
        return false
    }
}
