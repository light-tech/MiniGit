//
//  StatusProtocol.h
//  Protocol for git status's output container
//
//  Created by Lightech on 10/24/2048.
//

#import "Diff.h"
#import "Reference.h"

/**
 * Protocol for object to host the result of `git status` command where various information
 * will be passed progressively as we compute of the status to allow implementation in SwiftUI
 * to perform model-view binding.
 */
@protocol StatusProtocol

/**
 * Invoked when the current branch has been determined
 *
 * @param branchName Name of the current branch
 */
- (void)setCurrentBranch:(nonnull NSString*)branchName;

/**
 * Invoked to set the state of this repo
 *
 * @param state One of the enumeration in git_repository_state_t
 */
- (void)setState:(int)state;

/**
 * Invoked when staged changes have been computed
 *
 * @param changes The staged changes i.e. the diff between
 *                the index and the latest commit
 */
- (void)setStagedChanges:(nonnull Diff*)changes;

/**
 * Invoked when unstaged changes have been computed
 *
 * @param changes The unstaged changes i.e. the diff between
 *                the working directory and the index
 */
- (void)setUnstagedChanges:(nonnull Diff*)changes;

@end
