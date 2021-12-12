//
//  DiffLine.h
//  Declaration of DiffLine class which is data converted from libgit2's git_diff_line
//
//  Created by Lightech on 10/24/2048.
//

@interface DiffLine: NSObject

/**
 * ID to conform to SwiftUI's Identifiable
 */
@property (readonly, nonnull) NSUUID *id;

/**
 * The kind of change in this diff line: for example
 *  '+' if this line is added in the new file, or
 *  '-' if this line is deleted in the new file, or
 *  ' ' if this line simply gives some surrounding code for context of the change.
 */
@property (readonly, nonnull) NSString *kind;

/**
 * The diff line text
 */
@property (readonly, nonnull) NSString *text;

@end
