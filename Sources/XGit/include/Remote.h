//
//  Remote.h
//  Declaration of Repository class which is wrapper class for libgit2's git_remote
//
//  Created by Lightech on 10/24/2048.
//

@interface Remote: NSObject

/**
 * Name of the remote, can be used as its ID
 */
@property (readonly, nonnull) NSString *name;

/**
 * The URL of this remote
 */
@property (readonly, nonnull) NSString *url;

/**
 * No-op constructor for subclass
 */
- (nonnull instancetype)init;

@end
