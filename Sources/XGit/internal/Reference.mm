//
//  Reference.mm
//  Implementation of Objective-C class Reference
//
//  Created by Lightech on 10/24/2048.
//

@implementation Reference
{
    @public git_reference *ref;
}

- (nonnull instancetype)init
{
    ref = NULL;
    return self;
}

- (void)setLibGit2Reference:(git_reference* _Nonnull)ref
{
    self->ref = ref;

    self->_name = NSStringFromCString(git_reference_name(ref));
    self->_shorthand = NSStringFromCString(git_reference_shorthand(ref));

    self->_isSymbolic = (git_reference_type(ref) == GIT_REFERENCE_SYMBOLIC);
    self->_isBranch = (git_reference_is_branch(ref) != 0);
    self->_isTag = (git_reference_is_tag(ref) != 0);
    self->_isRemote = (git_reference_is_remote(ref) != 0);

    const char *branch_name = NULL;
    git_branch_name(&branch_name, ref);
    self->_branchName = NSStringFromCString(branch_name);
}

- (void)dealloc
{
    git_reference_free(ref);
}

@end
