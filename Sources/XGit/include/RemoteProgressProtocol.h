//
//  RemoteProgressProtocol.h
//  Protocol to communicate remote progress
//
//  Created by Lightech on 10/24/2048.
//

#import "CredentialProtocol.h"
#import "OID.h"
#import "PushUpdate.h"

/**
 * Protocol for handling remote network events/progresses such as those from `git clone`, `git push` and `git fetch`
 * Basically contain callbacks from libgit2 struct git_remote_callbacks.
 */
@protocol RemoteProgressProtocol

/**
 * Invoke when the operation is completed
 */
- (void)onComplete;

/**
 * Invoke to retrieve the credential we should use in this operation
 */
- (id<CredentialProtocol> _Nullable)getCredential;

/**
 * Invoke to report that credential is really needed
 */
- (void)mustSupplyCredential;

/**
 * Textual progress from the remote. Text send over the
 * progress side-band will be passed to this function (this is
 * the 'counting objects' output).
 *
 * See git_remote_callbacks.sideband_progress.
 */
- (void)onSidebandProgress:(nonnull NSString*)message;

/**
 * During the download of new data, this will be regularly
 * called with the current count of progress done by the
 * indexer.
 *
 * See git_remote_callbacks.transfer_progress and git_indexer_progress_cb.
 */
- (void)onTransferProgress:(unsigned int)total_objects :(unsigned int)indexed_objects :(unsigned int)received_objects :(unsigned int)local_objects :(unsigned int)total_deltas :(unsigned int)indexed_deltas :(size_t)received_bytes;

/**
 * Each time a reference is updated locally, this function
 * will be called with information about it.
 *
 * See git_remote_callbacks.update_tips
 */
- (void)onUpdateTips:(nonnull NSString*)refname :(nonnull OID*)a :(nonnull OID*)b;

/**
 * Function to call with progress information during pack
 * building. Be aware that this is called inline with pack
 * building operations, so performance may be affected.
 *
 * See git_remote_callbacks.pack_progress and git_packbuilder_progress.
 */
- (void)onPackProgress:(int)stage :(uint32_t)current :(uint32_t)total;

/**
 * Function to call with progress information during the
 * upload portion of a push. Be aware that this is called
 * inline with pack building operations, so performance may be
 * affected.
 *
 * See git_remote_callbacks.push_transfer_progress
 */
- (void)onPushTransferProgress:(unsigned int)current :(unsigned int)total :(size_t)bytes;

/**
 * Callback used to inform of the update status from the remote.
 *
 * Called for each updated reference on push. If `status` is
 * not `NULL`, the update was rejected by the remote server
 * and `status` contains the reason given.
 *
 * @param refname refname specifying to the remote ref
 * @param status status message sent from the remote
 * @param data data provided by the caller
 * @return 0 on success, otherwise an error
 *
 * See git_remote_callbacks.push_update_reference
 */
- (void)onPushUpdateReference:(nonnull NSString*)refname :(NSString* _Nullable)status;

/**
 * Called once between the negotiation step and the upload. It
 * provides information about what updates will be performed.
 *
 * See git_remote_callbacks.push_negotiation.
 */
- (void)onPushNegotiation:(nonnull NSArray<PushUpdate*> *)updates;

@end
