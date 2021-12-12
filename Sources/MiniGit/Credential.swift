//
//  Credential.swift
//  Implementation of the CredentialProtocol to supply the credential to network-related commands
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class Credential: Identifiable, Codable, CredentialProtocol {

    public enum Kind: String, CaseIterable, Identifiable, Codable {
        case ssh
        case password
        public var id: String { self.rawValue }
    }

    // Unique identifier
    public var id: String
    public var kind: Kind

    // The remote URLs this credential applies: when the remote URL starts with this string
    public var targetURL: String

    // For basic authentication
    public var userName: String?
    public var password: String?

    // For SSH authentication
    public var publicKey: String?
    public var privateKey: String?

    public init(id: String, kind: Kind, targetURL: String, userName: String, password: String) {
        self.id = id
        self.kind = kind
        self.targetURL = targetURL
        self.userName = userName
        self.password = password
    }

    public init(id: String, kind: Kind, targetURL: String, publicKey: String, privateKey: String) {
        self.id = id
        self.kind = kind
        self.targetURL = targetURL
        self.publicKey = publicKey
        self.privateKey = privateKey
    }

    public func isUserNamePasswordAuthenticationMethod() -> Bool {
        return kind == .password
    }

    public func getUserName() -> String {
        return userName!
    }

    public func getPassword() -> String {
        return password!
    }

}
