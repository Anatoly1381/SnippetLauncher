//
//  SnippetPopupView.swift
//  SnippetLauncher
//
//  Created by Anatoly Fedorov on 07/05/2025.
//

import SwiftUI
import HotKey

struct SnippetPopupView: View {
    @EnvironmentObject var viewModel: SnippetViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var hoveredID: UUID?
    @State private var isInserting = false
    @State private var hotKeys: [HotKey] = []
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.snippets.enumerated()), id: \.element.id) { index, snippet in
                                Button(action: {
                                    insertSnippet(snippet)
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
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(hoveredID == snippet.id ? .white : .primary)
                                                .padding(.leading, 2)
                                                .padding(.vertical, 2)
                                            
                                            Spacer()
                                            
                                            if index < 9 {
                                                Text("⌘\(index + 1)")
                                                    .font(.system(size: 16, weight: .regular))
                                                    .foregroundColor(
                                                        colorScheme == .dark ?
                                                            .white : // Белый цвет в ночной теме
                                                        Color(red: 0.60, green: 0.07, blue: 0.80) // Фиолетовый в дневной
                                                    )
                                                    .padding(.trailing, 15)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                        .padding(.leading, 10)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(isInserting)
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
                    .allowsHitTesting(false)
                
                VStack(alignment: .leading) {
                    if let hoveredID = hoveredID, let snippet = viewModel.snippets.first(where: { $0.id == hoveredID }) {
                        ScrollView(.vertical) {
                            Text(snippet.content)
                                .font(.body)
                                .padding(.leading, 8) // Выравнивание с иконкой звезды
                                .padding(.trailing, 20) // Правый отступ
                                .padding(.vertical, 12) // Вертикальные отступы
                                .frame(
                                    maxWidth: 488,
                                    alignment: .leading
                                )
                                .padding(.top, 0)
                        }
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 0, maxHeight: .infinity)
                .clipped()
                .padding(.top, 12)
            }
        }
        .contentShape(Rectangle())
        .frame(width: 720, height: 450)
        .background(
            Color.clear.contentShape(Rectangle()).onTapGesture {
                NSApp.windows.first?.close()
            }
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 10)
        )
        .padding()
        .onAppear {
            setupHotKeys()
        }
        .onChange(of: viewModel.snippets) {
            // Обновляем горячие клавиши
            setupHotKeys()

            // Принудительное обновление UI (если требуется)
            DispatchQueue.main.async {
                viewModel.objectWillChange.send()
            }
        }
    }

    private func setupHotKeys() {
        // Очищаем предыдущие горячие клавиши
        hotKeys.removeAll()
        
        // Создаем горячие клавиши только для существующих сниппетов
        for index in 0..<min(9, viewModel.snippets.count) {
            guard let key = Key(number: index + 1) else { continue }
            
            let hotKey = HotKey(key: key, modifiers: [.command])
            hotKey.keyDownHandler = {
                if index < viewModel.snippets.count {
                    insertSnippet(viewModel.snippets[index])
                }
            }
            hotKeys.append(hotKey)
        }
    }

    private func insertSnippet(_ snippet: SnippetModel) {
        guard !isInserting else { return }
        isInserting = true
        
        // Копируем текст в буфер обмена
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snippet.content, forType: .string)
        
        // Скрываем приложение
        NSApp.hide(nil)

        // Эмулируем Command+V через 0.2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let source = CGEventSource(stateID: .combinedSessionState)

            // Command down
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            cmdDown?.flags = .maskCommand
            cmdDown?.post(tap: .cghidEventTap)

            // V down
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            vDown?.flags = .maskCommand
            vDown?.post(tap: .cghidEventTap)

            // V up
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            vUp?.flags = .maskCommand
            vUp?.post(tap: .cghidEventTap)

            // Command up
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
            cmdUp?.post(tap: .cghidEventTap)

            // Закрываем окно сниппетов и сбрасываем его состояние
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let snippetWindow = AppDelegate.snippetWindow {
                    snippetWindow.close() // Полностью закрываем окно
                    AppDelegate.snippetWindow = nil // Сбрасываем состояние
                }
                self.isInserting = false
            }
        }
    }
}
