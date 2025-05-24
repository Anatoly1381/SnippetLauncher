//
//  SnippetPopupView.swift
//  MinimalSnippetInserter
//
//  Created by Anatoly Fedorov on 02/05/2025.
//



import SwiftUI

struct SnippetPopupView: View {
    @ObservedObject var viewModel: SnippetViewModel
    @State private var hoveredID: UUID?
    @Environment(\.presentationMode) var presentationMode // Добавлено

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ... остальное содержимое без изменений ...
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 10)
        )
        .padding()
    }

    func insertText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Закрываем текущее окно через presentationMode
        presentationMode.wrappedValue.dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Уменьшил задержку
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
        }
    }
}
