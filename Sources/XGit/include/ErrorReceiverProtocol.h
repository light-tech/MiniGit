//
//  ErrorReceiverProtocol.h
//  Protocol to communicate operational errors
//
//  Created by Lightech on 10/24/2048.
//

#import "GitError.h"

@protocol ErrorReceiverProtocol

/**
 * Signals an error encountered in the library
 *
 * @param code Error code of the libgit2 function.
 * @param error Error object with more details on the error such as a user-friendly message
 * @param extra_message Developer message to indicate where this error is encountered
 */
- (void)onError:(int)code :(GitError* _Nullable)error :(NSString* _Nullable)extra_message;

@end
