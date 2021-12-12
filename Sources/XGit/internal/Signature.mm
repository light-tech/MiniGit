//
//  Signature.mm
//  Implementation of Objective-C class Signature
//
//  Created by Lightech on 10/24/2048.
//

@implementation Signature
{
    @public git_signature *signature;
}

- (nonnull instancetype)init:(git_signature* _Nonnull)signature
{
    self->signature = signature;

    self->_name = NSStringFromCString(signature->name);
    self->_email = NSStringFromCString(signature->email);

    return self;
}

- (void)dealloc
{
    git_signature_free(signature);
}

@end
