//
//  OID.mm
//  Implementation of Objective-C class OID
//
//  Created by Lightech on 10/24/2048.
//

@implementation OID
{
    git_oid   oid;
    NSString *oid_string;
}

- (nonnull instancetype)init:(const git_oid* _Nonnull)oid
{
    self->oid = *oid;

    char oid_str[GIT_OID_HEXSZ+1];
    git_oid_tostr(oid_str, GIT_OID_HEXSZ+1, oid);
    self->oid_string = NSStringFromCString(oid_str);

    return self;
}

- (nonnull NSString*)description
{
    return oid_string;
}

@end
