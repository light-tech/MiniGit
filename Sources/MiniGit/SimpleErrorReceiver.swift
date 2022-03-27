//
//  SimpleErrorReceiver.swift
//  Implementation of ErrorReceiverProtocol to contain error of git operations
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class SimpleErrorReceiver: ErrorReceiverProtocol, ObservableObject {

    @Published public var extraMessage: String?
    @Published public var errorCode: Int32?
    @Published public var error: GitError?
    @Published public var hasError = false

    public func clearError() {
        error = nil
        errorCode = nil
        extraMessage = nil
        hasError = false
    }

    public func onError(_ code: Int32, _ error: GitError?, _ extra_message: String?) {
        DispatchQueue.main.async {
            print("Error \(code): \(extra_message ?? "") \(error != nil ? error!.message : "")")
            if self.errorCode == nil {
                self.errorCode = code
                self.error = error
                self.extraMessage = extra_message
                self.hasError = true
            }
        }
    }

}
