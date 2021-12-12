//
//  Diff.h
//  Wrapper value class for libgit2's git_diff type
//
//  Created by Lightech on 10/24/2048.
//

#import "DiffDelta.h"

@interface Diff: NSObject

/**
 * Initialize an empty diff
 */
- (nonnull instancetype)init;

/**
 * The list of deltas (a.k.a. file changes)
 */
@property (readonly, nonnull) NSArray<DiffDelta*> *deltas;

@end
