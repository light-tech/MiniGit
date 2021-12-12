//
//  DiffLine.mm
//  Implementation of Objective-C class DiffLine
//
//  Created by Lightech on 10/24/2048.
//

@implementation DiffLine
{
}

- (nonnull instancetype)init:(const git_diff_line* _Nonnull)line
{
    self->_id = [[NSUUID alloc] init];
    self->_text = NSStringFromBuffer(line->content, line->content_len);
    self->_kind = NSStringFromBuffer(&(line->origin), 1);

    return self;
}

@end
