//
//  PushUpdate.h
//  Declaration of PushUpdate class which is wrapper class for libgit2's git_push_update
//  This class is used by RemoteProgressProtocol
//
//  Created by Lightech on 10/24/2048.
//

#import "OID.h"

@interface PushUpdate: NSObject

@property (readonly, nonnull) NSString *srcRefName;

@property (readonly, nonnull) NSString *dstRefName;

@property (readonly, nonnull) OID *src;

@property (readonly, nonnull) OID *dst;

@end
