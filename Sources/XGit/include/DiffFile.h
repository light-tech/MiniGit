//
//  DiffFile.h
//  Declaration of DiffFile class which is data converted from libgit2's git_diff_file
//
//  Created by Lightech on 10/24/2048.
//

@interface DiffFile: NSObject

/**
 * The file path, could be null to indicate when the old/new file is deleted/added in a diff
 */
@property (readonly) NSString * _Nullable path;

@end
