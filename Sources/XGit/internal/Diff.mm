//
//  Diff.mm
//  Implementation of Objective-C class Diff
//
//  Created by Lightech on 10/24/2048.
//

#import "DiffLine.mm"
#import "DiffFile.mm"
#import "DiffHunk.mm"
#import "DiffDelta.mm"
#import "DiffCollector.mm"

@implementation Diff
{
    git_diff *diff;
}

- (void)dealloc
{
    git_diff_free(diff);
}

- (nonnull instancetype)init
{
    self->diff = NULL;
    self->_deltas = [[NSMutableArray alloc] init];

    return self;
}

- (nonnull instancetype)init:(git_diff* _Nonnull)diff
{
    self->diff = diff;
    self->_deltas = DiffCollector(diff).getDeltas();

    return self;
}

@end
