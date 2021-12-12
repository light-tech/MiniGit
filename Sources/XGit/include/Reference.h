//
//  Reference.h
//  Declaration of Repository class which is wrapper class for libgit2's git_reference
//  A Git reference could be a local branch, a remote branch, a tag or a note.
//
//  Created by Lightech on 10/24/2048.
//

@interface Reference: NSObject

/**
 * Full name of the reference such as `refs/heads/main` or `refs/remotes/origin/main`
 */
@property (readonly, nonnull) NSString *name;

/**
 * Short hand for the reference such as `main` or `origin/main`
 */
@property (readonly, nonnull) NSString *shorthand;

/**
 * Indicate if this is a symbolic reference (i.e. a reference that points to another
 * reference instead of a concrete git object)
 */
@property (readonly) BOOL isSymbolic;

/**
 * Indicate if this reference is a local branch i.e. one that lives in `refs/heads`
 */
@property (readonly) BOOL isBranch;

/**
 * Indicate if this reference is a remote branch i.e. one that lives in `refs/remotes`
 */
@property (readonly) BOOL isRemote;

/**
 * Indicate if this reference is a tag
 */
@property (readonly) BOOL isTag;

/**
 * The name of the branch if this reference is indeed a branch
 */
@property (readonly) NSString* _Nullable branchName;

@end
