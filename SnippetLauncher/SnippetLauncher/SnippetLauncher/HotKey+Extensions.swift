//
//  HotKey+Extensions.swift
//  SnippetLauncher
//
//  Created by Anatoly Fedorov on 08/05/2025.
//

import HotKey

extension Key {
    init?(number: Int) {
        guard (1...9).contains(number) else { return nil }
        self.init(string: "\(number)")
    }
}
