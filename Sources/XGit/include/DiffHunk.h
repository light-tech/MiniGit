//
//  DiffHunk.h
//  Declaration of DiffHunk class which is data converted from libgit2's git_diff_hunk
//
//  Created by Lightech on 10/24/2048.
//

#import "DiffLine.h"

@interface DiffHunk: NSObject

/**
 * ID to conform to SwiftUI's Identifiable
 */
@property (readonly, nonnull) NSUUID *id;

/**
 * Header for the hunk giving information such as the lines that get changed
 */
@property (readonly, nonnull) NSString *header;

/**
 * A list of diff lines in this hunk
 */
@property (readonly, nonnull) NSArray<DiffLine*> *lines;

@end
