//
//  PushUpdate.mm
//  Implementation of Objective-C class PushUpdate
//
//  Created by Lightech on 10/24/2048.
//

@implementation PushUpdate
{
}

- (nonnull instancetype)init:(const git_push_update* _Nonnull)push_update
{
    self->_srcRefName = NSStringFromCString(push_update->src_refname);
    self->_dstRefName = NSStringFromCString(push_update->dst_refname);
    self->_src = [[OID alloc] init :&(push_update->src)];
    self->_dst = [[OID alloc] init :&(push_update->dst)];

    return self;
}

@end
