//
//  CheckoutHandler.mm
//  Single-use struct to perform git checkout and git reset
//
//  Created by Lightech on 10/24/2048.
//

#import "CheckoutProgressReporter.mm"
#import "GitErrorReporter.mm"

struct CheckoutHandler: CheckoutProgressReporter, GitErrorReporter {

    CheckoutHandler(id<CheckoutProtocol> checkoutProgress, id<ErrorReceiverProtocol> errorReceiver):
        CheckoutProgressReporter(checkoutProgress),
        GitErrorReporter(errorReceiver) {
    }

    ~CheckoutHandler() {
        git_commit_free(target_commit);
        git_reference_free(branch);
        git_annotated_commit_free(target);
    }

    /** Checkout a NON-SYMBOLIC LOCAL branch */
    void checkoutBranch(git_repository *repo, git_reference* ref) {
        git_annotated_commit_from_ref(&target, repo, ref);
        target_ref = git_reference_name(ref);

        // Checkout a raw commit
        // git_annotated_commit_lookup(&co.target, repo, git_commit_id(commit->commit));

        git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;

        /** Setup our checkout options from the parsed options */
        checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE;

        setupCheckoutCallbacks(&checkout_opts);

        /** Grab the commit we're interested to move to */
        if (reportError(git_commit_lookup(&target_commit, repo, git_annotated_commit_id(target)), "Checkout: Failed to lookup commit"))
            return;

        /**
         * Perform the checkout so the workdir corresponds to what target_commit
         * contains.
         *
         * Note that it's okay to pass a git_commit here, because it will be
         * peeled to a tree.
         */
        if (reportError(git_checkout_tree(repo, (const git_object *)target_commit, &checkout_opts), "Checkout: Failed to checkout tree"))
            return;

        /**
         * Now that the checkout has completed, we have to update HEAD.
         *
         * Depending on the "origin" of target (ie. it's an OID or a branch name),
         * we might need to detach HEAD.
         */
        if (git_annotated_commit_ref(target)) {
            const char *target_head;

            target_head = git_annotated_commit_ref(target);

            git_repository_set_head(repo, target_head);
        } else {
            git_repository_set_head_detached_from_annotated(repo, target);
        }
    }

    void createLocalTrackingBranch(git_repository* repo, git_reference *ref) {
        if (git_reference_is_remote(ref)) {
            git_annotated_commit_from_ref(&target, repo, ref);

            const char *remote_branch_name = NULL;
            git_branch_name(&remote_branch_name, ref);

            const char *local_branch_name = determineLocalBranchName(repo, remote_branch_name);

            git_branch_create_from_annotated(&branch, repo, local_branch_name, target, 0);
        }
    }

    static const char *determineLocalBranchName(git_repository *repo, const char *remote_branch_name) {
        git_strarray remotes;
        git_remote_list(&remotes, repo);

        auto len = strlen(remote_branch_name);
        for(size_t i = 0; i < remotes.count; i++) {
            // Check if "remote_name/" is a prefix of "remote_branch_name"
            // i.e. if "remote_branch_name" = "remote_name/branch_name"
            auto remote_name = remotes.strings[i];
            auto remote_name_length = strlen(remote_name);
            if (remote_name_length < len && remote_branch_name[remote_name_length] == '/' &&
                strncmp(remote_branch_name, remote_name, remote_name_length) == 0) {

                return remote_branch_name + remote_name_length + 1;
            }
        }

        git_strarray_dispose(&remotes);

        // In the scenario that we cannot find the remote prefix
        return remote_branch_name;
    }

    void resetCurrentBranchToCommit(git_repository *repo, git_commit *commit) {
        git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;
        setupCheckoutCallbacks(&checkout_opts);

        git_annotated_commit_lookup(&target, repo, git_commit_id(commit));

        git_reset_from_annotated(repo, target, GIT_RESET_HARD, &checkout_opts);
    }

    git_annotated_commit *target = NULL;
    const char *target_ref = NULL;
    git_reference *branch = NULL;
    git_commit *target_commit = NULL;
};

