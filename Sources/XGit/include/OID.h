//
//  OID.h
//  Declaration of OID class which is wrapper class for libgit2's git_oid
//
//  Created by Lightech on 10/24/2048.
//

@interface OID: NSObject

/**
 * Description to allow printing the SHA-1 hex string
 */
- (nonnull NSString*)description;

@end
