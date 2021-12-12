//
//  GitCommitGraph.swift
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class GitCommitGraph: CommitGraphProtocol, ObservableObject {

    @Published public var commits = [GitCommit]()

    public var needLoading = true

    public init() {
    }

    public func add(_ commit: Commit) {
        commits.append(commit as! GitCommit)
    }

    public func clear() {
        commits.removeAll()
    }

}
