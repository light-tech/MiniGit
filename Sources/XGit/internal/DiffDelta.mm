//
//  DiffDelta.mm
//  Implementation of Objective-C class DiffDelta
//
//  Created by Lightech on 10/24/2048.
//

@implementation DiffDelta
{
}

- (nonnull instancetype)init:(const git_diff_delta* _Nonnull)delta
{
    self->_id = [[NSUUID alloc] init];
    self->_theOldFile = [[DiffFile alloc] init :delta->old_file];
    self->_theNewFile = [[DiffFile alloc] init :delta->new_file];

    return self;
}

- (void)setHunks:(nonnull NSMutableArray<DiffHunk*> *)hunks
{
    self->_hunks = hunks;
}

@end
