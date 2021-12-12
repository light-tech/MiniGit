//
//  DiffHunk.mm
//  Implementation of Objective-C class DiffHunk
//
//  Created by Lightech on 10/24/2048.
//

@implementation DiffHunk
{
}

- (nonnull instancetype)init:(const git_diff_hunk* _Nonnull)hunk
{
    self->_id = [[NSUUID alloc] init];
    self->_header = NSStringFromBuffer(hunk->header, hunk->header_len);
    self->_lines = [[NSMutableArray alloc] init];

    return self;
}

- (void)setLines:(nonnull NSMutableArray<DiffLine*> *)lines
{
    self->_lines = lines;
}

@end
