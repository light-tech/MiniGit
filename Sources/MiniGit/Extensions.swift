//
//  Extensions.swift
//  Extension of the various data structs in MiniGit such as Remote, DiffDelta, DiffLine, DiffHunk to comply
//  with the Identifiable protocol so that we can use them in SwiftUI views such as List and ForEach
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

extension OID {
    public var shortDescription: String {
        let desc = description()
        let index = desc.index(desc.startIndex, offsetBy: 7)

        return String(desc[..<index])
    }
}

extension Remote: Identifiable {
    public var id: String {
        name
    }
}

extension DiffDelta: Identifiable {
    public var path: String {
        if let oldpath = theOldFile.path {
            return oldpath
        } else {
            return theNewFile.path!
        }
    }
}

extension DiffLine: Identifiable {
    public var textTrimmed: String {
        return text.trimmingCharacters(in: .newlines)
    }
}

extension DiffHunk: Identifiable {
}
