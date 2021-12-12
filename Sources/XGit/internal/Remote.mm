//
//  Remote.mm
//  Implementation of Objective-C class Remote
//
//  Created by Lightech on 10/24/2048.
//

@implementation Remote
{
    @public git_remote *remote;
}

- (void)dealloc
{
    git_remote_free(remote);
}

- (nonnull instancetype)init
{
    remote = NULL;
    return self;
}

- (void)setLibGit2Remote:(git_remote* _Nonnull)remote
{
    self->remote = remote;

    self->_name = NSStringFromCString(git_remote_name(remote));
    self->_url = NSStringFromCString(git_remote_url(remote));
}

@end
