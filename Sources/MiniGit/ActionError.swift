//
//  ActionError.swift
//  A simple Error struct
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI

@available(iOS 14, macOS 11.0, *)
public struct ActionError: Identifiable, LocalizedError {

    public var id: String { message }

    public let message: String

    public var localizedDescription: String {
        return message
    }

    public init(message: String) {
        self.message = message
    }

}
