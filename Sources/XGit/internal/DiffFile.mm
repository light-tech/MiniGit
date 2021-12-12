//
//  DiffFile.mm
//  Implementation of Objective-C class DiffFile
//
//  Created by Lightech on 10/24/2048.
//

@implementation DiffFile
{
}

- (nonnull instancetype)init:(const git_diff_file&)file
{
    self->_path = NSStringFromCString(file.path);

    return self;
}

@end
