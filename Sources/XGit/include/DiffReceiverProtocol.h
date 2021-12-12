//
//  DiffReceiverProtocol.h
//  Protocol to communicate `git diff` result
//
//  Created by Lightech on 10/24/2048.
//

#import "Diff.h"

@protocol DiffReceiverProtocol

- (void)setChanges:(nonnull Diff*)changes;

@end
