//
//  GitError.mm
//  Implementation of Objective-C class GitError
//
//  Created by Lightech on 10/24/2048.
//

#import "GitError.h"

@implementation GitError
{
}

- (nonnull instancetype)init:(const git_error * _Nullable)err
{
    self->_message = NSStringFromCString(err->message);
    self->_klass = err->klass;

    return self;
}

@end
