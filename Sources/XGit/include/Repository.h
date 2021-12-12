//
//  Repository.h
//  Declaration of Repository class
//
//  Created by Lightech on 10/24/2048.
//

#import <Foundation/Foundation.h>

#import "GitError.h"
#import "Commit.h"
#import "Diff.h"
#import "Remote.h"
#import "Reference.h"

#import "ErrorReceiverProtocol.h"
#import "DiffReceiverProtocol.h"
#import "CheckoutProtocol.h"
#import "MergeProtocol.h"
#import "StatusProtocol.h"
#import "CommitGraphProtocol.h"
#import "RemoteProgressProtocol.h"

/**
 * Wrapper class for libgit2 git_repository.
 * This is the heart of the library: All API call goes through here.
 *
 * With the exception of `Diff`, every other class provide no public
 * constructor so their constructions is indirect via the repository
 * that owns them.
 */
@interface Repository: NSObject

/**
 * Create a repository operating at the given file system location.
 * The repository does not have to exists. Call `open` and check the
 * `hasRepo` property to determine if there is a repo at the given
 * location.
 *
 * @param path The path to the repository
 * @return the new instance of the repository
 */
- (nonnull instancetype)init:(nonnull NSString*)path;

/**
 * Factory method to create a new instance of Commit owned by this
 * repository. Swift client can override this method to return
 * subclasses of Commit befitting its purpose (for e.g. to provide
 * data binding for SwiftUI). Every Commit returned in other methods
 * will be made by this method.
 *
 * @return a new instance of a Commit subclass ready for further
 * properties set-up
 */
- (nonnull Commit*)makeCommit;

/**
 * Factory method to create a new instance of Reference owned by this
 * repository. See `makeCommit` for details.
 *
 * @return a new instance of a Reference subclass ready for further
 * properties set-up
 */
- (nonnull Reference*)makeReference;

/**
 * Factory method to create a new instance of Remote (owned by this
 * repository). See `makeCommit` for details.
 *
 * @return a new instance of a Remote subclass ready for further
 * properties set-up
 */
- (nonnull Remote*)makeRemote;

/**
 * Indicate if the repo exists i.e. the `.git` dir exists at the
 * path provided in constructor.
 */
- (BOOL)exists;

/**
 * Update the list of references in each generated Commit
 */
- (void)updateReferencesTargets;

/**
 * Open the repository.
 *
 * Check `exists()` afterwards to see if the repository really exists.
 */
- (void)open;

/**
 * Create a.k.a. `git init` the repository, creating the `.git`
 * directory and the structure therein. Check `hasRepo` property
 * to see if the repo is successfully created.
 */
- (void)create;

/**
 * Clone repository from a remote URL
 * Client code is expected to run this method in background thread
 * if necessary. Also, do not run this if the repo already exists.
 *
 * @param url URL to the remote repository
 * @param remoteProgress Object to receive clone progress report
 * @param checkoutProgress Object to receive progress of the checkout
 *                         step of the clone operation
 */
- (void)clone:(nonnull NSString*)url
             :(id<RemoteProgressProtocol> _Nonnull)remoteProgress
             :(id<CheckoutProtocol> _Nullable)checkoutProgress
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Get the repository's status such as staged files, unstaged files, etc.
 *
 * @param gitStatusReceiver Object to progressively receive the status report.
 */
- (void)status:(id<StatusProtocol> _Nonnull)gitStatusReceiver
              :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Stage a file to the index for the next commit
 *
 * @param path Path to the file to stage relative to the repo root
 */
- (void)stage:(nonnull NSString*)path
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Unstage a file from the index
 *
 * @param path Path to the file to unstage relative to the repo root
 */
- (void)unstage:(nonnull NSString*)path
               :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Obtain the user's signature (user name and email) from the repo
 * configuration.
 */
- (Signature* _Nullable)getSignature;

/**
 * Set the user's signature (user name and email) in the repo
 * configuration.
 */
- (void)setSignature:(nonnull NSString*)name :(nonnull NSString*)email;

/**
 * Commit the current staged changes in the index.
 *
 * @param message The commit message
 */
- (void)commit:(nonnull NSString*)message
              :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Retrieve the revision history as a list of commits ordered by time
 * and by topology.
 *
 * @param commitGraph Instance of a commit graph, ready to be filled up
 */
- (void)log:(id<CommitGraphProtocol> _Nonnull)commitGraph;

/**
 * Compute the diff between two commits
 *
 * @param baseCommit The base commit
 * @param targetCommit The target commit
 * @param diffReceiver Object to receive the diff result
 */
- (void)diff:(nonnull Commit*)baseCommit
            :(nonnull Commit*)targetCommit
            :(id<DiffReceiverProtocol> _Nonnull)diffReceiver;

/**
 * Create a new local-tracking branch pointing at the given commit.
 *
 * @param branchName Name of the branch to be created
 * @param commit The commit the new branch should point to
 */
- (void)createBranch:(nonnull NSString*)branchName
                    :(nonnull Commit*)commit;

/**
 * Create a local-tracking branch (e.g. main) that synces with a
 * remote branch (e.g. origin/main) if it does not exists.
 *
 * @param ref The remote branch (non-symbolic ref)
 */
- (void)createLocalTrackingBranch:(nonnull Reference*)ref;

/**
 * Create a light-weight tag pointing at the given commit.
 *
 * @param tagName Name of the tag to be created
 * @param commit The commit the new branch should point to
 */
- (void)createLightweightTag:(nonnull NSString*)tagName
                            :(nonnull Commit*)commit;

/**
 * Remove a local reference
 *
 * @param ref The reference to remove
 */
- (void)removeReference:(nonnull Reference*)ref;

/**
 * HARD reset the current branch to a commit, which has the following
 * effects:
 *
 * (i) Update (= check out) the working tree to match the files
 *     at the given commit. So all changes in the working tree not
 *     committed WILL BE DISCARDED.
 *
 * (ii) Make the current branch point at that commit. Consequently,
 *      if you are resetting to a previous commit, ALL subsequent
 *      commit WILL BE LOST if you have no reference to them.
 *
 * @param commit Target commit to reset this branch to
 * @param checkoutProgress Object to receive the checkout progress
 */
- (void)reset:(nonnull Commit*)commit
             :(id<CheckoutProtocol> _Nullable)checkoutProgress
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Checkout a reference (branch), updating files in the working
 * directory with those in the commit pointed at by the reference.
 * Only support checking out a LOCAL BRANCH.
 *
 * @param reference The reference/branch to checkout (must not be
 *                  a symbolic reference like HEAD) and is a local
 *                  branch
 * @param checkoutProgress Object to receive the checkout progress
 */
- (void)checkout:(nonnull Reference*)reference
                :(id<CheckoutProtocol> _Nullable)checkoutProgress
                :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Merge the references (branches) into the working tree. At the moment
 * the actual implementation ONLY SUPPORTS A SINGLE REFERENCE i.e. no
 * octopus merge. Also, unlike `git merge` command, we do NOT automatically
 * create a merge commit in case the merge is successful. So client MUST
 * make sure to call `commit` to get the repository out of the merge state
 * (after resolving all possible merge conflicts) or `reset` to discard the
 * merge operation.
 *
 * @param refs The list of references to merge (cannot have more than 1
 *             reference at the moment)
 * @param mergeProgress Object to receive merge progress and result
 */
- (void)merge:(nonnull NSArray<Reference*> *)refs
             :(id<MergeProtocol> _Nullable)mergeProgress
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Retrieve the list of configured remotes in this repo.
 */
- (nonnull NSArray<Remote*>*)getRemotes;

/**
 * Add a new remote to the configuration.
 *
 * @param name Name of the remote (e.g. `origin`)
 * @param url URL to the remote
 */
- (Remote* _Nullable)addRemote:(nonnull NSString*)name :(nonnull NSString*)url;

/**
 * Remove a configured remote.
 *
 * @param remote The remote to delete, must be one previously returned from
 *                 `getRemote` or added
 */
- (void)removeRemote:(nonnull Remote*)remote;

/**
 * Push all branches to a remote.
 *
 * @param remote The remote to push
 * @param force Force update the remote's branches and references
 * @param remoteProgress Object to receive push progress such as bytes uploaded
 */
- (void)push:(nonnull Remote*)remote
            :(BOOL)force
            :(id<RemoteProgressProtocol> _Nonnull)remoteProgress
            :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

/**
 * Fetch changes from a remote.
 *
 * @param remote The remote to push
 * @param remoteProgress Object to receive push progress such as bytes downloaded
 */
- (void)fetch:(nonnull Remote*)remote
             :(id<RemoteProgressProtocol> _Nonnull)remoteProgress
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver;

@end
