//
//  GitCommit.swift
//  Implementation of abstract Commit class
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class GitCommit: Commit, Identifiable, ObservableObject {

    public var id: OID {
        oid
    }

    @Published public var refs = [GitReference]()

    public var parents = [GitCommit]()

    public override func setParents(_ parents: [Commit]) {
        self.parents = parents as! [GitCommit]
    }

    public override func add(_ ref: Reference) {
        refs.append(ref as! GitReference)
    }

    public override func removeAllReferences() {
        refs.removeAll()
    }

}
