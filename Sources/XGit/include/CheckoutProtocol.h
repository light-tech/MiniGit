//
//  CheckoutProtocol.h
//  Protocol to communicate git checkout progress
//
//  Created by Lightech on 10/24/2048.
//

@protocol CheckoutProtocol

/**
 * Callback to notify the consumer of checkout progress.
 * See member git_checkout_options.progress_cb.
 */
- (void)onCheckoutProgress:(NSString* _Nullable)path :(size_t)completed_steps :(size_t)total_steps;

/**
 * Notify the consumer of performance data.
 * See member git_checkout_options.perfdata_cb.
 */
- (void)onCheckoutPerfData:(size_t)mkdir_calls :(size_t)stat_calls :(size_t)chmod_calls;

/**
 * Call back when the operation is complete
 */
- (void)onComplete;

@end
