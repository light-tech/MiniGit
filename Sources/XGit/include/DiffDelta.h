//
//  DiffDelta.h
//  Declaration of DiffDelta class which is data converted from libgit2's git_diff_delta
//
//  Created by Lightech on 10/24/2048.
//

#import "DiffFile.h"
#import "DiffHunk.h"

@interface DiffDelta: NSObject

/**
 * ID to conform to SwiftUI's Identifiable
 */
@property (readonly, nonnull) NSUUID *id;

/**
 * The old file (base of comparison)
 */
@property (readonly, nonnull) DiffFile *theOldFile;

/**
 * The new file (target of comparison)
 *     base + this diff = target
 *
 * Note: We would like to write newFile but Objective-C doesn't like that.
 */
@property (readonly, nonnull) DiffFile *theNewFile;

/**
 * The list of diff hunks
 */
@property (readonly, nonnull) NSArray<DiffHunk*> *hunks;

@end
