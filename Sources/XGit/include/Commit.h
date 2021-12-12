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
 * (Abstract method) Set the list of references.
 *
 * @param ref Reference that points at this commit
 */
- (void)setParents:(nonnull NSArray<Commit*> *)parents;

/**
 * (Abstract method) Add a reference that points to this commit
 * The implementation does nothing. Client should implement this.
 *
 * @param ref Reference that points at this commit
 */
- (void)addReference:(nonnull Reference*)ref;

/**
 * (Abstract method) Clear the list of Reference's pointing at this commit
 */
- (void)removeAllReferences;

@end
