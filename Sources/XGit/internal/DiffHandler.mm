//
//  DiffHandler.mm
//  Single-use struct to perform git diff (between two commits' tree)
//
//  Created by Lightech on 10/24/2048.
//

#import "DiffReceiverProtocol.h"

struct DiffHandler {

    DiffHandler(id<DiffReceiverProtocol> diffReceiver) {
        this->diffReceiver = diffReceiver;
    }

    ~DiffHandler() {
        git_tree_free(old_tree);
        git_tree_free(new_tree);
    }

    git_tree *old_tree = NULL;
    git_tree *new_tree = NULL;
    id<DiffReceiverProtocol> diffReceiver;

    void diff(git_repository *repo, git_commit *from_commit, git_commit *to_commit) {
        git_diff *diff;

        git_commit_tree(&old_tree, from_commit);
        git_commit_tree(&new_tree, to_commit);

        git_diff_options diff_opts;
        git_diff_options_init(&diff_opts, GIT_DIFF_OPTIONS_VERSION);
        git_diff_tree_to_tree(&diff, repo, old_tree, new_tree, &diff_opts);

        Diff* result = [[Diff alloc] init :diff];
        [diffReceiver setChanges :result];
    }
};
