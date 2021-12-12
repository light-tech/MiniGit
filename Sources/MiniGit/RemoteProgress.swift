//
//  RemoteProgress.swift
//
//  Implementation of RemoteProgressProtocol to receive progress report
//  for remote commands such as `git clone`, `git push` and `git fetch`.
//  Note that a clone is essentially a fetch (i.e. download) which can
//  then be viewed as a push from the remote repo's perspective.
//
//  You can imagine how a push usually proceeds:
//
//   1. First we need to negotiate the changes i.e. the difference between
//      the local and the remote to figure out what we should send over
//      (the commits and the files). This depends on the local branch and
//      the remote tracking branch since we want to sync them.
//
//   2. We pack the necessary data and upload it over the network.
//
//   3. The server unpack the data and update the remote tracking branches
//      or reject the changes (e.g. non-forwarded) when it should.
//
//  A fetch is just a push from the remote's perspective: The remote
//  negotiates the changes in step 1, packes the data and sends it to us in
//  step 2 and in step 3, we update our remote tracking branches e.g. origin/main
//  as indicated by the remote.
//
//  So for a push, we will have progress in both packing and uploading stage
//  whereas in a fetch/clone, we only have progress in the downloading stage.
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class RemoteProgress: RemoteProgressProtocol, ObservableObject {

    public struct UpdateTip: Identifiable {
        public var id = UUID()

        public var refname: String
        public var a: OID
        public var b: OID
    }

    public struct PushUpdateRef: Identifiable {
        public var id = UUID()

        public var refname: String
        public var status: String?
    }

    var repo: GitRepository
    var credential: Credential? = nil
    public var errorReceiver = SimpleErrorReceiver()

    @Published public var operation: String = ""
    @Published public var inProgress: Bool = false

    // Progress message from remote (such as counting objects, packing, compressing percentage)
    @Published public var messageFromRemote: String = ""

    // Downloading progress from remote (fetch/clone)
    @Published public var fetchTransferInProgress = false
    @Published public var transferTotalObjects: UInt32 = 0
    @Published public var transferIndexedObjects: UInt32 = 0
    @Published public var transferReceivedObjects: UInt32 = 0
    @Published public var transferLocalObjects: UInt32 = 0
    @Published public var transferTotalDeltas: UInt32 = 0
    @Published public var transferIndexedDeltas: UInt32 = 0
    @Published public var transferReceivedBytes = 0

    // Uploading progress to remote (push)
    @Published public var pushTransferInProgress = false
    @Published public var pushTransferCurrent: UInt32 = 0
    @Published public var pushTransferTotal: UInt32 = 0
    @Published public var pushTransferBytes = 0

    // Pack building progress (before uploading)
    @Published public var packingInProgress = false
    @Published public var packingStage: Int32 = 0
    @Published public var packingCurrent: UInt32 = 0
    @Published public var packingTotal: UInt32 = 0

    // List of remote references updated (in local repo) after fetch
    @Published public var updateTips = [UpdateTip]()

    // List of push reference updates negotiated
    @Published public var pushUpdates = [PushUpdate]()

    // List of refs updated in the remote repo after push
    // Note that this is correlated to pushUpdates in that pushUpdates is what we want
    // the remote to update and the remote might refuse to do that, for example, due to
    // conflicts.
    @Published public var pushUpdateRefs = [PushUpdateRef]()

    public init(_ repo: GitRepository) {
        self.repo = repo
    }

    public func clearState(_ op: String, _ cred: Credential?) {
        credential = cred
        operation = op
        inProgress = true

        messageFromRemote = ""
        errorReceiver.clearError()
        pushUpdates.removeAll()
        updateTips.removeAll()
        pushUpdateRefs.removeAll()
        packingInProgress = false
        pushTransferInProgress = false
        fetchTransferInProgress = false
    }

    public func onComplete() {
        DispatchQueue.main.async {
            self.inProgress = false
            self.repo.onRepositoryExistenceChanged() // To refresh the hasRepo field after a successful clone

            // Push updates the targets of remote tracking refs (to match the local ones
            // e.g. [origin/main] = [main]) so we need to update the list of references
            // that annotates the relevant commits. Push does not changes the commit graph or the list of commits.

            // Likewise, fetch also updates the targets of remote tracking refs to what is
            // currently on the server so we need to update the list of references that annotates
            // the relevant commits. Fetch does not changes the commit graph.
            // However, it could create new remote-tracking refs.
            self.repo.onReferencesListChanged()
            self.repo.onReferencesTargetsChanged()
        }
    }

    public func getCredential() -> CredentialProtocol? {
        return credential
    }

    public func mustSupplyCredential() {
        errorReceiver.onError(-1, nil, "Credential is required!")
    }

    public func onSidebandProgress(_ message: String) {
        DispatchQueue.main.async {
            self.messageFromRemote = "Remote: \(message)"
        }
    }

    public func onTransferProgress(_ total_objects: UInt32, _ indexed_objects: UInt32, _ received_objects: UInt32, _ local_objects: UInt32, _ total_deltas: UInt32, _ indexed_deltas: UInt32, _ received_bytes: Int) {
        DispatchQueue.main.async {
            self.fetchTransferInProgress = true
            self.transferTotalObjects = total_objects
            self.transferIndexedObjects = indexed_objects
            self.transferReceivedObjects = received_objects
            self.transferLocalObjects = local_objects
            self.transferTotalDeltas = total_deltas
            self.transferIndexedDeltas = indexed_deltas
            self.transferReceivedBytes = received_bytes
        }
    }

    public func onUpdateTips(_ refname: String, _ a: OID, _ b: OID) {
        DispatchQueue.main.async {
            self.updateTips.append(UpdateTip(refname: refname, a: a, b: b))
        }
    }

    public func onPackProgress(_ stage: Int32, _ current: UInt32, _ total: UInt32) {
        DispatchQueue.main.async {
            self.packingInProgress = true
            self.packingStage = stage
            self.packingCurrent = current
            self.packingTotal = total
        }
    }

    public func onPushTransferProgress(_ current: UInt32, _ total: UInt32, _ bytes: Int) {
        DispatchQueue.main.async {
            self.pushTransferInProgress = true
            self.pushTransferCurrent = current
            self.pushTransferTotal = total
            self.pushTransferBytes = bytes
        }
    }

    public func onPushUpdateReference(_ refname: String, _ status: String?) {
        DispatchQueue.main.async {
            self.pushUpdateRefs.append(PushUpdateRef(refname: refname, status: status))
        }
    }

    public func onPushNegotiation(_ updates: [PushUpdate]) {
        DispatchQueue.main.async {
            self.pushUpdates = updates

            // If there is no update needed
            if updates.count == 0 {
                self.messageFromRemote = "Already up-to-date."
            }
        }
    }
}
