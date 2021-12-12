//
//  CredentialsManager.swift
//  A simple JSON-backed credentials manager
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI

@available(iOS 14, macOS 11.0, *)
public class CredentialsManager: ObservableObject {

    @Published public var allCredentials = [Credential]()

    var credentialsFileUrl: URL

    public init(credentialsFileUrl: URL) {
        // Load credentials from file
        self.credentialsFileUrl = credentialsFileUrl
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: credentialsFileUrl)
            allCredentials = try decoder.decode([Credential].self, from: data)
        } catch let error {
            print(error)
        }
    }

    public func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(allCredentials)
        FileManager.default.createFile(atPath: credentialsFileUrl.path,
                                       contents: data,
                                       attributes: nil)
    }

    public func addOrUpdate(_ oldcred: Credential? = nil, _ cred: Credential) throws {
        if let old_cred = oldcred {
            // Update the old credential with new information
            if let old_cred_index = allCredentials.firstIndex(where: {$0.id == old_cred.id}) {
                allCredentials.remove(at: old_cred_index)
                allCredentials.insert(cred, at: old_cred_index) // Check ID?
                try save()
            } else {
                print("Cannot find the old credential in the list! Something is wrong!")
            }
        } else {
            // Add a new credential to the list
            if cred.id == "" {
                throw ActionError(message: "The credential ID must not be empty!")
            }
            else if allCredentials.firstIndex(where: {$0.id == cred.id}) != nil {
                throw ActionError(message: "The credential with the same ID already exists. Cannot add another one.")
            } else {
                allCredentials.append(cred)
                try save()
            }
        }
    }

    public func remove(offsets: IndexSet) {
        allCredentials.remove(atOffsets: offsets)
        do {
            try save()
        } catch let error {
            print(error)
        }
    }

    public func getCredentialForUrl(_ url: String) -> Credential? {
        return allCredentials.first(where: { url.hasPrefix($0.targetURL) })
    }
}
