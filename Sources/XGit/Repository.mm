//
//  Repository.mm
//  Implementation of Objective-C class Repository, our main library entry point
//
//  Note that this file will include all source files in `internal/` since we need to access their internal members.
//
//  Created by Lightech on 10/24/2048.
//

#import <string>
#import <map>

#import "Repository.h"

#import "git2.h"

#import "internal/StringHelpers.mm"

#import "internal/Reference.mm"
#import "internal/Commit.mm"
#import "internal/Remote.mm"
#import "internal/PushUpdate.mm"
#import "internal/Diff.mm"

#import "internal/RemoteHandler.mm"
#import "internal/DiffHandler.mm"
#import "internal/CheckoutHandler.mm"
#import "internal/MergeHandler.mm"
#import "internal/IndexHandler.mm"
#import "internal/StatusHandler.mm"

static int libgit2_initialized = false;

struct OIDCompare
{
    bool operator()(const git_oid &lhs, const git_oid &rhs) const
    {
        return git_oid_cmp(&lhs, &rhs) < 0;
    }
};

@implementation Repository
{
    char           *_pathToRepo;
    git_repository *repo;

    // Cache created Obj-C Commit objects
    // Note that we should not cache created Reference because their target cannot be updated
    // after creation and so subsequent command might not work correctly.
    std::map<git_oid, Commit*, OIDCompare> _oid_to_commit;
}

- (nonnull instancetype)init:(nonnull NSString*)path
{
    if (!libgit2_initialized) {
        git_libgit2_init();
    }

    self->_pathToRepo = strdup([path UTF8String]);
    self->repo = NULL;

    return self;
}

- (void)dealloc
{
    free(_pathToRepo);
    git_repository_free(repo);
}

- (nonnull Commit*)makeCommit
{
    return [[Commit alloc] init];
}

- (nonnull Reference*)makeReference
{
    return [[Reference alloc] init];
}

- (nonnull Remote*)makeRemote
{
    return [[Remote alloc] init];
}

- (Commit* _Nullable) getOrAddCommitByID:(const git_oid&)oid
{
    // Note that the OID supplied is not guaranteed to exists
    // For example, 00000...0 for the parent of the initial commit

    auto iter = _oid_to_commit.find(oid);

    if (iter == _oid_to_commit.end()) {
        git_commit *commit;

        if (git_commit_lookup(&commit, repo, &oid) == 0) {
            Commit *result = [self makeCommit];
            [result setLibGit2Commit :commit :&oid];
            _oid_to_commit[oid] = result;

            return result;
        }

        return nil;
    }

    return iter->second;
}

- (void)updateCommitParents:(nonnull Commit*)commit
{
    if (commit->computedParents)
        return;

    NSMutableArray<Commit*> *parents = [[NSMutableArray alloc] init];

    auto num_parents = git_commit_parentcount(commit->commit);
    for(auto i = 0; i < num_parents; i++) {
        auto parent_oid = git_commit_parent_id(commit->commit, i);
        auto parent_commit = [self getOrAddCommitByID :*parent_oid];
        [parents addObject :parent_commit];
    }

    [commit setParents :parents];
    commit->computedParents = true;
}

- (void)updateAllCommitsParents
{
    for(const auto &p : _oid_to_commit) {
        [self updateCommitParents :p.second];
    }
}

- (Reference*) getReferenceByName:(const char*)name
{
    git_reference *ref;
    git_reference_lookup(&ref, repo, name);
    Reference *result = [self makeReference];
    [result setLibGit2Reference :ref];

    return result;
}

int addReferenceToTargetCommit(const char *name, void *payload)
{
    Repository *repository = (__bridge Repository*)payload;
    git_oid target_oid;
    git_reference_name_to_id(&target_oid, repository->repo, name);
    auto commit = [repository getOrAddCommitByID :target_oid];
    auto ref = [repository getReferenceByName :name];
    [commit addReference :ref];

    return 0;
}

- (void)updateReferencesTargets
{
    // Clear the list of references in all commit
    for(const auto &p : _oid_to_commit) {
        [p.second removeAllReferences];
    }

    // Go through each reference and add it to its target
    git_reference_foreach_name(repo, addReferenceToTargetCommit, (__bridge void*)self);
}

- (BOOL)exists
{
    return repo != NULL;
}

- (void)open
{
    if (repo != NULL)
        return;

    git_repository_open(&repo, _pathToRepo);
}

- (void)create
{
    // Ideally we should report error as well
    git_repository_init(&repo, _pathToRepo, false);
}

- (void)clone:(nonnull NSString*)url
             :(id<RemoteProgressProtocol> _Nonnull)remoteProgress
             :(id<CheckoutProtocol> _Nullable)checkoutProgress
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    RemoteHandler(remoteProgress, checkoutProgress, errorReceiver).clone(&repo, [url UTF8String], _pathToRepo);
}

- (void)status:(id<StatusProtocol> _Nonnull)gitStatusReceiver :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    StatusHandler(gitStatusReceiver, errorReceiver).status(repo);
}

- (void)stage:(nonnull NSString*)path :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    IndexHandler(errorReceiver).stage(repo, [path UTF8String]);
}

- (void)unstage:(nonnull NSString*)path :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    IndexHandler(errorReceiver).unstage(repo, [path UTF8String]);
}

- (Signature* _Nullable)getSignature
{
    git_signature *signature;
    if (git_signature_default(&signature, repo) != 0)
        return nil;

    return [[Signature alloc] init :signature];
}

- (void)setSignature:(nonnull NSString*)name :(nonnull NSString*)email
{
    git_config *config;
    git_repository_config(&config, repo);

    git_config_set_string(config, "user.name", [name UTF8String]);
    git_config_set_string(config, "user.email", [email UTF8String]);

    git_config_free(config);
}

- (void)commit:(nonnull NSString*)message :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    IndexHandler(errorReceiver).commit(repo, [message UTF8String]);
}

- (void)log:(id<CommitGraphProtocol>)commitGraph
{
    git_revwalk *walk;
    git_revwalk_new(&walk, repo);

    // Push all references as starting points
    git_reference_foreach_name(repo, [](const char *name, void *payload) {
        git_revwalk_push_ref((git_revwalk*) payload, name);

        return 0;
    }, walk);

    git_revwalk_sorting(walk, GIT_SORT_TIME | GIT_SORT_TOPOLOGICAL /* | GIT_SORT_REVERSE | GIT_SORT_NONE */);

    [commitGraph clear];

    git_oid commit_oid;
    while (git_revwalk_next(&commit_oid, walk) == 0) {
        auto commit = [self getOrAddCommitByID :commit_oid];
        if (commit != nil) {
            [commitGraph addCommit :commit];
        }
    }

    git_revwalk_free(walk);

    [self updateAllCommitsParents];
    [self updateReferencesTargets];
}

- (void)diff:(nonnull Commit*)baseCommit :(nonnull Commit*)targetCommit :(id<DiffReceiverProtocol> _Nonnull)diffReceiver
{
    DiffHandler(diffReceiver).diff(repo, baseCommit->commit, targetCommit->commit);
}

- (Commit* _Nullable)getReferenceTargetCommit:(nonnull Reference*)ref
{
    // TODO Implement
    return NULL;
}

- (void)createBranch:(nonnull NSString*)branchName :(Commit*)commit
{
    git_reference *result;
    git_branch_create(&result, repo, [branchName UTF8String], commit->commit, 0);
}

- (void)createLocalTrackingBranch:(nonnull Reference*)ref
{
    CheckoutHandler(nil, nil).createLocalTrackingBranch(repo, ref->ref);
}

- (void)createLightweightTag:(nonnull NSString*)tagName :(Commit*)commit
{
    git_oid oid;
    git_tag_create_lightweight(&oid, repo, [tagName UTF8String], (git_object*)(commit->commit), 1);
}

- (void)removeReference:(nonnull Reference*)ref
{
    // TODO Make sure that we do not delete the current branch!
    git_reference_delete(ref->ref);
}

- (void)reset:(nonnull Commit*)commit
             :(id<CheckoutProtocol> _Nullable)checkoutProgress
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    CheckoutHandler(checkoutProgress, errorReceiver).resetCurrentBranchToCommit(repo, commit->commit);
}

- (void)checkout:(nonnull Reference*)reference
                :(id<CheckoutProtocol> _Nullable)checkoutProgress
                :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    CheckoutHandler(checkoutProgress, errorReceiver).checkoutBranch(repo, reference->ref);
}

- (void)merge:(nonnull NSArray<Reference*> *)refs
             :(id<MergeProtocol> _Nullable)mergeProgress
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    MergeHandler(mergeProgress, errorReceiver).mergeBranchesToHEAD(repo, refs);
    [mergeProgress onComplete];
}

- (NSArray<Remote*>*)getRemotes
{
    git_strarray rems;
    git_remote_list(&rems, repo);
    NSMutableArray<Remote*>* remotes = [[NSMutableArray alloc] init];
    for(size_t i = 0; i < rems.count; i++) {
        git_remote *r;
        git_remote_lookup(&r, repo, rems.strings[i]);
        Remote *rmt = [self makeRemote];
        [rmt setLibGit2Remote :r];
        [remotes addObject :rmt];
    }
    git_strarray_dispose(&rems);

    return remotes;
}

- (Remote* _Nullable)addRemote:(nonnull NSString*)name :(nonnull NSString*)url
{
    git_remote *out = NULL;
    git_remote_create(&out, repo, [name UTF8String], [url UTF8String]);

    if (out == NULL)
        return nil;

    Remote * rem = [self makeRemote];
    [rem setLibGit2Remote :out];
    return rem;
}

- (void)removeRemote:(nonnull Remote*)remote
{
    git_remote_delete(repo, git_remote_name(remote->remote));
}

- (void)push:(nonnull Remote*)remote
            :(BOOL)force
            :(id<RemoteProgressProtocol> _Nonnull)remoteProgress
            :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    RemoteHandler(remoteProgress, errorReceiver).push(repo, force, remote->remote);
}

- (void)fetch:(nonnull Remote*)remote
             :(id<RemoteProgressProtocol> _Nonnull)remoteProgress
             :(id<ErrorReceiverProtocol> _Nullable)errorReceiver
{
    RemoteHandler(remoteProgress, errorReceiver).fetch(remote->remote);
}

@end
