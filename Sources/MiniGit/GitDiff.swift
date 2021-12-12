//
//  GitDiff.swift
//  Implementation of DiffProtocol to host the result of the `git diff` command, mainly to show diff between commits/revisions
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class GitDiff: DiffReceiverProtocol, ObservableObject {

    @Published public var changes: Diff = Diff()

    public init() {
    }

    public func setChanges(_ changes: Diff) {
        self.changes = changes
    }

}
