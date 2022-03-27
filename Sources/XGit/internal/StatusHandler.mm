//
//  StatusHandler.mm
//  Single-use struct to compute git status
//
//  Created by Lightech on 10/24/2048.
//

#import "StatusProtocol.h"
#import "GitErrorReporter.mm"

struct StatusHandler: GitErrorReporter {

    StatusHandler(id<StatusProtocol> gitStatusReceiver, id<ErrorReceiverProtocol> errorReceiver):
		GitErrorReporter(errorReceiver) {
        this->gitStatusReceiver = gitStatusReceiver;
    }

    id<StatusProtocol> gitStatusReceiver;

    ~StatusHandler() {
        git_index_free(index);
        git_reference_free(head_ref);
        git_tree_free((git_tree*)head_tree);
    }

    git_index *index = NULL;
    git_reference *head_ref = NULL;
    git_object *head_tree = NULL;
    git_diff_options diff_opts;

    void status(git_repository *repo) {
        int state = git_repository_state(repo);
        [gitStatusReceiver setState :state];

        determineCurrentBranch(repo);

        git_diff_options_init(&diff_opts, GIT_DIFF_OPTIONS_VERSION);
        diff_opts.flags |= GIT_DIFF_INCLUDE_UNTRACKED;

        computeUnstagedChanges(repo);
        computeStagedChanges(repo);
    }

private:
    void computeConflicts(git_index *index)
    {
        git_index_conflict_iterator *conflicts;
        const git_index_entry *ancestor;
        const git_index_entry *our;
        const git_index_entry *their;
        int err = 0;

        if (reportError(git_index_conflict_iterator_new(&conflicts, index), "failed to create conflict iterator"))
            return;

        while ((err = git_index_conflict_next(&ancestor, &our, &their, conflicts)) == 0) {
            fprintf(stderr, "conflict: a:%s o:%s t:%s\n",
                    ancestor ? ancestor->path : "NULL",
                    our->path ? our->path : "NULL",
                    their->path ? their->path : "NULL");
        }

        if (err != GIT_ITEROVER) {
            fprintf(stderr, "error iterating conflicts\n");
        }

        git_index_conflict_iterator_free(conflicts);
    }

    void determineCurrentBranch(git_repository *repo) {
        if (reportError(git_reference_lookup(&head_ref, repo, "HEAD"), "Warning: The repo has no HEAD. It is probably just created."))
            return;

        switch (git_reference_type(head_ref)) {
            case GIT_REFERENCE_DIRECT:
                printf("HEAD points directly to a commit! Cannot determine current branch. We are probably in DETACHED HEAD state.\n");
                break;

            case GIT_REFERENCE_SYMBOLIC: {
                const char *head_target = git_reference_symbolic_target(head_ref);
                git_reference *head_target_ref = NULL;
                if (git_reference_lookup(&head_target_ref, repo, head_target) == 0 &&
                    git_reference_is_branch(head_target_ref)) {
                    const char *result;
                    git_branch_name(&result, head_target_ref);
                    NSString *currentBranch = NSStringFromCString(result);
                    [gitStatusReceiver setCurrentBranch :currentBranch];
                    git_reference_free(head_target_ref);
                }
            }
                break;

            default:
                // printf("Invalid reference type!\n");
                break;
        }
        git_reference_free(head_ref);
        head_ref = NULL;
    }

    void computeUnstagedChanges(git_repository *repo) {
        if (reportError(git_repository_index(&index, repo), "Cannot open index"))
            return;

        git_diff *unstaged_changes = NULL;

        if (reportError(git_diff_index_to_workdir(&unstaged_changes, repo, index, &diff_opts), "Error computing unstaged changes"))
            return;

        Diff* unstagedChanges = [[Diff alloc] init :unstaged_changes];
        [gitStatusReceiver setUnstagedChanges :unstagedChanges];
    }

    void computeStagedChanges(git_repository *repo) {
        head_tree = NULL;
        if (git_repository_head(&head_ref, repo) == 0) {
            if (reportError(git_reference_peel(&head_tree, head_ref, GIT_OBJECT_TREE), "Warning: HEAD does not point to a commit tree! This repo might be corrupted!"))
                return;
        }

        git_diff *staged_changes;

        if (reportError(git_diff_tree_to_index(&staged_changes, repo, (git_tree*)head_tree, index, &diff_opts), ""))
            return;

        Diff* stagedChanges = [[Diff alloc] init :staged_changes];
        [gitStatusReceiver setStagedChanges :stagedChanges];
    }
};
