//
//  SnippetModel.swift
//  MinimalSnippetInserter
//
//  Created by Anatoly Fedorov on 07/05/2025.
//

import Foundation

struct SnippetModel: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var tags: [String]
}

extension SnippetModel {
    var tagsString: String {
        get { tags.joined(separator: ", ") }
        mutating set {
            tags = newValue
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
    }
}
