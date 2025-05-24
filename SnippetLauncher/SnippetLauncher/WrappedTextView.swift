//
//  WrappedTextView.swift
//  SnippetLauncher
//
//  Created by Anatoly Fedorov on 11/05/2025.
//

import SwiftUI
import AppKit

struct WrappedTextView: NSViewRepresentable {
    @Binding var text: String
    let isEditable: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        
        let textView = NSTextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.string = text
        
        // Настройки для plain text
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsImageEditing = false
        textView.usesFontPanel = false
        textView.usesRuler = false
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Обновляем текст только если он изменился извне
        if !context.coordinator.isEditing && textView.string != text {
            textView.string = text
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: WrappedTextView
        weak var textView: NSTextView?
        var isEditing = false
        
        init(_ parent: WrappedTextView) {
            self.parent = parent
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }
        
        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
            updateParentText()
        }
        
        func textDidChange(_ notification: Notification) {
            updateParentText()
        }
        
        private func updateParentText() {
            guard let textView = textView else { return }
            parent.text = textView.string
        }
    }
}
