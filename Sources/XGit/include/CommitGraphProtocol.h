//
//  CommitGraphProtocol.h
//  Protocol to host git history
//
//  Created by Lightech on 10/24/2048.
//

#import "Commit.h"

@protocol CommitGraphProtocol

/**
 * Clear all commits in the graph prior to rev-walking
 */
- (void)clear;

/**
 * Add a new commit to the existing commit graph
 */
- (void)addCommit:(nonnull Commit*)commit;

@end
