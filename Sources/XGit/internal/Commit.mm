//
//  Commit.mm
//  Implementation of Objective-C class Commit
//
//  Created by Lightech on 10/24/2048.
//

#include "OID.mm"
#include "Signature.mm"

@implementation Commit
{
@public git_commit *commit;
@public bool computedParents;
}

- (nonnull instancetype)init
{
    commit = NULL;
    return self;
}

- (void)setLibGit2Commit:(git_commit* _Nonnull)commit :(const git_oid* _Nonnull)commit_oid
{
    self->commit = commit;

    const char* summary = git_commit_summary(commit);
    self->_summary = NSStringFromCString(summary);

    const char* msg = git_commit_message(commit);
    self->_message = NSStringFromCString(msg);

    self->_oid = [[OID alloc] init :commit_oid];

    double time = static_cast<double>(git_commit_time(commit));
    self->_time = [[NSDate alloc] initWithTimeIntervalSince1970 :time];

    git_signature* author = NULL;
    git_signature_dup(&author, git_commit_author(commit));
    self->_author = [[Signature alloc] init :author];

    self->computedParents = false;
}

- (void)dealloc
{
    git_commit_free(commit);
}

- (void)setParents:(nonnull NSArray<Commit*> *)parents
{
    self->computedParents = true;
}

- (void)addReference:(nonnull Reference*)ref
{
}

- (void)removeAllReferences
{
}

@end
