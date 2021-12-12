//
//  GitReference.swift
//  Implementation of abstract Reference class
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class GitReference: Reference, Identifiable, ObservableObject {

    public var id = UUID()

}
