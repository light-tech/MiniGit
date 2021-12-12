//
//  GitRepository.swift
//  Subclass of XGit.Repository class
//   * Conform to Identifiable and ObservableObject to work in SwiftUI data-binding
//   * Manage the repository states for UI
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class GitRepository: Repository, Identifiable, ObservableObject {

    public typealias Status = GitStatus

    public let id = UUID()

    @Published public var hasRepo: Bool = false

    public var location: URL
    public var credentialsManager: CredentialsManager

    public var status = GitStatus()
    public var commitGraph = GitCommitGraph()
    public var remoteProgress: RemoteProgress!
    public var mergeProgress = MergeCheckoutProgress()
    public var errorReceiver = SimpleErrorReceiver()

    public init(_ location: URL, _ credentialsManager: CredentialsManager) {
        self.location = location
        self.credentialsManager = credentialsManager

        super.init(location.path)

        self.remoteProgress = RemoteProgress(self)
    }

    public override func makeCommit() -> Commit {
        return GitCommit()
    }

    public override func makeReference() -> Reference {
        return GitReference()
    }

    public func updateStatus() {
        errorReceiver.clearError()
        status(self.status, self.errorReceiver)
    }

    public func updateCommitGraph() {
        log(commitGraph)
        commitGraph.needLoading = false
    }

    func onRepositoryExistenceChanged() {
        self.hasRepo = self.exists()
    }

    func onCommitGraphChanged() {
        updateCommitGraph()
    }

    func onStatusChanged() {
        updateStatus()
    }

    func onReferencesListChanged() {
        // TODO We want to update the commit history with new reference annotations
        // But is it wise to do so with a reload history?
    }

    func onReferencesTargetsChanged() {
        updateReferencesTargets()
    }

    public override func open() {
        super.open()
        onRepositoryExistenceChanged()
    }

    public override func create() {
        super.create()
        onRepositoryExistenceChanged()
    }

    public override func stage(_ path: String, _ errorReceiver: ErrorReceiverProtocol?) {
        super.stage(path, errorReceiver)
        onStatusChanged()
    }

    public override func unstage(_ path: String, _ errorReceiver: ErrorReceiverProtocol?) {
        super.unstage(path, errorReceiver)
        onStatusChanged()
    }

    public override func commit(_ message: String, _ errorReceiver: ErrorReceiverProtocol?) {
        super.commit(message, errorReceiver)

        // Once the commit was made, the status of the repo changed.
        onStatusChanged()

        // A new commit is created so we have to refresh the entire commit graph
        // and not just the list of references annotated for each commit
        // (to add the newly created one + update the HEAD reference)
        onCommitGraphChanged()
    }

    public override func createBranch(_ branchName: String, _ commit: Commit) {
        super.createBranch(branchName, commit)
        onReferencesListChanged()
        onReferencesTargetsChanged()
    }

    public override func createLocalTrackingBranch(_ ref: Reference) {
        super.createLocalTrackingBranch(ref)
        onReferencesListChanged()
        onReferencesTargetsChanged()
    }

    public override func createLightweightTag(_ tagName: String, _ commit: Commit) {
        super.createLightweightTag(tagName, commit)
        onReferencesListChanged()
        onReferencesTargetsChanged()
    }

    public override func remove(_ ref: Reference) {
        super.remove(ref)
        onReferencesListChanged()
    }

    public override func reset(_ commit: Commit, _ checkoutProgress: CheckoutProtocol?, _ errorReceiver: ErrorReceiverProtocol?) {
        super.reset(commit, checkoutProgress, errorReceiver)

        // Upon reset, we must inform the UI that a ref (the current branch) has
        // updated target and the the commit now acquires a new reference pointing
        // at it.

        onReferencesTargetsChanged()

        // However, we do not need to do that for checkout for in that case we are
        // switching to a new branch so actually there is no change to the
        // commit graph, including the list of references that annotates the commit.
        // Likewise, merge updates the working tree and the index, so there is no change
        // to the commit history and the references' targets until the user commits.
    }

    public func stage(_ path: String) {
        errorReceiver.clearError()
        stage(path, self.errorReceiver)
    }

    public func unstage(_ path: String) {
        errorReceiver.clearError()
        unstage(path, self.errorReceiver)
    }

    public func commit(_ message: String) {
        errorReceiver.clearError()
        commit(message, self.errorReceiver)
    }

    public func clone(_ url: String) {
        remoteProgress.clearState("Clone from \(url)", credentialsManager.getCredentialForUrl(url))
        DispatchQueue.global().async {
            self.clone(url, self.remoteProgress, nil /*self.mergeProgress*/, self.remoteProgress.errorReceiver)
        }
    }

    public func reset(_ commit: Commit) {
        mergeProgress.clearState("Reset", forMerging: false)
        reset(commit, self.mergeProgress, self.mergeProgress.errorReceiver)
    }

    public func checkout(_ ref: Reference) {
        mergeProgress.clearState("Check out \(ref.shorthand)", forMerging: false)
        checkout(ref, self.mergeProgress, self.mergeProgress.errorReceiver)
    }

    public func merge(_ refs: [Reference]) {
        mergeProgress.clearState("Merge \(refs[0].shorthand)", forMerging: true)
        merge(refs, self.mergeProgress, self.mergeProgress.errorReceiver)
    }

    public func push(_ remote: Remote, _ force: Bool) {
        remoteProgress.clearState("Push to \(remote.name)", credentialsManager.getCredentialForUrl(remote.url))
        DispatchQueue.global().async {
            self.push(remote, force, self.remoteProgress, self.remoteProgress.errorReceiver)
        }
    }

    public func fetch(_ remote: Remote) {
        remoteProgress.clearState("Fetch from \(remote.name)", credentialsManager.getCredentialForUrl(remote.url))
        DispatchQueue.global().async {
            self.fetch(remote, self.remoteProgress, self.remoteProgress.errorReceiver)
        }
    }

}
