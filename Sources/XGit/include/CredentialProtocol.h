//
//  CredentialProtocol.h
//  Protocol for Credential object, allowing us to query for credential information
//  such as user name and password (personal access token) so that we can create
//  the credential object for libgit2; while allowing it to conform to the various
//  other SwiftUI protocols for manipulation in the GUI.
//
//  TODO Add SSH credential
//
//  Created by Lightech on 10/24/2048.
//

@protocol CredentialProtocol

/**
 * @return true if this credential object is for simple username-password
 *         authentication
 */
- (BOOL)isUserNamePasswordAuthenticationMethod;

/**
 * @return the user name for username-password authentication method
 */
- (nonnull NSString*)getUserName;

/**
 * @return the password for username-password authentication method or
 *         personal access token (PAT) in many Git hosting services
 */
- (nonnull NSString*)getPassword;

@end
