//
//  GitError.h
//  Declaration of GitError class which is wrapper class for libgit2's git_error
//
//  Created by Lightech on 10/24/2048.
//

@interface GitError: NSObject

@property (readonly, nonnull) NSString *message;

@property (readonly) int klass;

@end
