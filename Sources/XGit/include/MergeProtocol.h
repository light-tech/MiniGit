//
//  MergeProtocol.h
//  Protocol to communicate merge progress
//  Note that a merge could simply be a checkout in case we could fast-forward.
//  So this protocol extends CheckoutProtocol.
//
//  Created by Lightech on 10/24/2048.
//

#import "CheckoutProtocol.h"

@protocol MergeProtocol <CheckoutProtocol>

/**
 * Notify client the merge analysis result such as "up to date" (no merge needed)
 * or "fast forward" (a simple checkout and a target change are performed) or a
 * "normal" merge is needed.
 */
- (void)setMergeAnalysisResult:(int)result;

@end
