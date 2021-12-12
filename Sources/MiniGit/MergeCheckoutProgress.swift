//
//  MergeCheckoutProgress.swift
//  Implementation of both CheckoutProtocol and MergeProtocol to host the
//  results of `git reset`, `git checkout` and `git merge` command.
//
//  Created by Lightech on 10/24/2048.
//

import SwiftUI
import XGit

@available(iOS 14, macOS 11.0, *)
public class MergeCheckoutProgress: CheckoutProtocol, MergeProtocol, ObservableObject {

    // Copy from git_merge_analysis_t, declared in libgit2 merge.h
    public enum MergeAnalysis: Int32 {
        /** No merge is possible.  (Unused.) */
        case NONE = 0

        /**
         * A "normal" merge; both HEAD and the given merge input have diverged
         * from their common ancestor.  The divergent commits must be merged.
         */
        case NORMAL = 1 // (1 << 0)

        /**
         * All given merge inputs are reachable from HEAD, meaning the
         * repository is up-to-date and no merge needs to be performed.
         */
        case UP_TO_DATE = 2 // (1 << 1)

        /**
         * The given merge input is a fast-forward from HEAD and no merge
         * needs to be performed.  Instead, the client can check out the
         * given merge input.
         */
        case FASTFORWARD = 4 // (1 << 2)

        /**
         * The HEAD of the current repository is "unborn" and does not point to
         * a valid commit.  No merge can be performed, but the caller may wish
         * to simply set HEAD to the target commit(s).
         */
        case UNBORN = 8 // (1 << 3)
    }

    public var errorReceiver = SimpleErrorReceiver()

    @Published public var mergeAnalysis: MergeAnalysis = .NONE
    @Published public var isMerge: Bool = false

    @Published public var operation: String = ""
    @Published public var message: String = ""
    @Published public var inProgress: Bool = false

    @Published public var currentlyCheckoutPath: String?
    @Published public var completedSteps = 0
    @Published public var totalSteps = 0

    @Published public var mkdirCalls = 0
    @Published public var statCalls = 0
    @Published public var chmodCalls = 0

    public init() {
    }

    public func clearState(_ op: String, forMerging merge: Bool) {
        operation = op
        isMerge = merge

        message = ""
        inProgress = true
        currentlyCheckoutPath = nil
        errorReceiver.clearError()
    }

    public func onCheckoutProgress(_ path: String?, _ completed_steps: Int, _ total_steps: Int) {
        // Note that
        //  * total_steps = the total number of files to check out
        //  * completed_steps = the number of files checked out thus far
        currentlyCheckoutPath = path
        completedSteps = completed_steps
        totalSteps = total_steps
    }

    public func onCheckoutPerfData(_ mkdir_calls: Int, _ stat_calls: Int, _ chmod_calls: Int) {
        mkdirCalls = mkdir_calls
        statCalls = stat_calls
        chmodCalls = chmod_calls
        inProgress = false
    }

    public func onComplete() {
        inProgress = false
    }

    public func setMergeAnalysisResult(_ result: Int32) {
        if let a = MergeAnalysis(rawValue: result) {
            mergeAnalysis = a
        } else {
            print("Unexpected merge analysis result \(result)")
        }
    }

}
