//
//  Commit.h
//  Declaration of Commit class which is wrapper class for libgit2's git_commit
//
//  Created by Lightech on 10/24/2048.
//

#import "OID.h"
#import "Signature.h"
#import "Reference.h"

@interface Commit: NSObject

/**
 * OID of this commit
 */
@property (readonly, nonnull) OID *oid;

/**
 * Full commit message
 */
@property (readonly, nonnull) NSString *message;

/**
 * Single line commit summary
 */
@property (readonly, nonnull) NSString *summary;

/**
 * Author's signature
 */
@property (readonly, nonnull) Signature *author;

/**
 * Commit date and time
 */
@property (readonly, nonnull) NSDate *time;

/**
 * This commit's parents (empty for the initial commit, more than one
 * for a merge commit). Populated by `Repository.log`, which computes
 * and sets this via `setParents:` as it walks the graph.
 */
@property (readonly, nonnull) NSArray<Commit*> *parents;

/**
 * References (branches, remote-tracking branches, tags) that currently
 * point directly at this commit. Populated by
 * `Repository.updateReferencesTargets`, which calls `addReference:` /
 * `removeAllReferences` as it walks the repository's refs.
 */
@property (readonly, nonnull) NSArray<Reference*> *references;

/**
 * Sets this commit's parents. Called by `Repository` while walking the
 * commit graph; a subclass that overrides this to add its own behavior
 * should call `super`.
 *
 * @param parents This commit's parent commits
 */
- (void)setParents:(nonnull NSArray<Commit*> *)parents;

/**
 * Records a reference that points to this commit. Called by
 * `Repository` while walking the repository's refs; a subclass that
 * overrides this to add its own behavior should call `super`.
 *
 * @param ref Reference that points at this commit
 */
- (void)addReference:(nonnull Reference*)ref;

/**
 * Clears the list of references pointing at this commit.
 */
- (void)removeAllReferences;

@end
