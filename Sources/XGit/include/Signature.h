//
//  Signature.h
//  Declaration of Signature class which is Objective-C wrapper class for libgit2's git_signature to contain author's information
//
//  Created by Lightech on 10/24/2048.
//

@interface Signature: NSObject

/**
 * Author's name
 */
@property (readonly, nonnull) NSString *name;

/**
 * Author's email
 */
@property (readonly, nonnull) NSString *email;

@end
