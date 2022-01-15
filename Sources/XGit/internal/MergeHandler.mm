//
//  MergeHandler.mm
//  Single-use struct to perform git merge
//
//  Created by Lightech on 10/24/2048.
//

#import "CheckoutHandler.mm"
#import "GitErrorReporter.mm"

struct MergeHandler: CheckoutProgressReporter, GitErrorReporter {

    MergeHandler(id<MergeProtocol> mergeProgress, id<ErrorReceiverProtocol> errorReceiver):
        CheckoutProgressReporter(mergeProgress),
        GitErrorReporter(errorReceiver) {
        this->mergeProgress = mergeProgress;
    }

    ~MergeHandler() {
        for(int i = 0; i < annotated_count; i++) {
            git_annotated_commit_free(annotated[i]);
        }
        delete[] annotated;

        // Used in fast-forward
        git_reference_free(target_ref);
        git_reference_free(new_target_ref);
        git_object_free(target);
    }

    git_annotated_commit **annotated = NULL;
    size_t annotated_count = 0;

    void mergeBranchesToHEAD(git_repository *repo, NSArray<Reference*> *refs)
    {
        annotated_count = refs.count;
        annotated = new git_annotated_commit*[refs.count];
        for(int i = 0; i < refs.count; i++) {
            git_annotated_commit_from_ref(&annotated[i], repo, refs[i]->ref);
        }

        git_index *index;
        git_merge_analysis_t analysis;
        git_merge_preference_t preference;
        int err = 0;

        int state = git_repository_state(repo);
        if (state != GIT_REPOSITORY_STATE_NONE) {
            fprintf(stderr, "repository is in unexpected state %d\n", state);
            return;
        }

        err = git_merge_analysis(&analysis, &preference,
                                 repo,
                                 (const git_annotated_commit **)this->annotated,
                                 this->annotated_count);
        if (reportError(err, "merge analysis failed")) {
            return err;
        }

        if (analysis & GIT_MERGE_ANALYSIS_UP_TO_DATE) {
            printf("Already up-to-date\n");
            [mergeProgress setMergeAnalysisResult :GIT_MERGE_ANALYSIS_UP_TO_DATE];
            return 0;
        } else if (analysis & GIT_MERGE_ANALYSIS_UNBORN ||
                  (analysis & GIT_MERGE_ANALYSIS_FASTFORWARD &&
                  !(preference & GIT_MERGE_PREFERENCE_NO_FASTFORWARD))) {
            const git_oid *target_oid;
            if (analysis & GIT_MERGE_ANALYSIS_UNBORN) {
                [mergeProgress setMergeAnalysisResult :GIT_MERGE_ANALYSIS_UNBORN];
                printf("Unborn\n");
            } else {
                [mergeProgress setMergeAnalysisResult :GIT_MERGE_ANALYSIS_FASTFORWARD];
                printf("Fast-forward\n");
            }

            /* Since this is a fast-forward, there can be only one merge head */
            target_oid = git_annotated_commit_id(this->annotated[0]);
            assert(this->annotated_count == 1);

            return perform_fastforward(repo, target_oid, (analysis & GIT_MERGE_ANALYSIS_UNBORN));
        } else if (analysis & GIT_MERGE_ANALYSIS_NORMAL) {
            [mergeProgress setMergeAnalysisResult :GIT_MERGE_ANALYSIS_NORMAL];

            git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;
            git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;
            setupCheckoutCallbacks(&checkout_opts);

            merge_opts.flags = 0;
            merge_opts.file_flags = GIT_MERGE_FILE_STYLE_DIFF3;

            checkout_opts.checkout_strategy = GIT_CHECKOUT_FORCE|GIT_CHECKOUT_ALLOW_CONFLICTS;

            if (preference & GIT_MERGE_PREFERENCE_FASTFORWARD_ONLY) {
                printf("Fast-forward is preferred, but only a merge is possible\n");
                return -1;
            }

            err = git_merge(repo,
                            (const git_annotated_commit **)this->annotated, this->annotated_count,
                            &merge_opts, &checkout_opts);
            if (reportError(err, "merge failed")) {
                return err;
            }
        }

        return 0;
    }

private:

    id<MergeProtocol> mergeProgress;

    git_reference *target_ref = NULL;
    git_reference *new_target_ref = NULL;
    git_object *target = NULL;

    int perform_fastforward(git_repository *repo, const git_oid *target_oid, int is_unborn)
    {
        git_checkout_options ff_checkout_options = GIT_CHECKOUT_OPTIONS_INIT;
        setupCheckoutCallbacks(&ff_checkout_options);

        if (is_unborn) {
            const char *symbolic_ref = NULL;
            git_reference *head_ref = NULL;

            /* HEAD reference is unborn, lookup manually so we don't try to resolve it */
            if (reportError(git_reference_lookup(&head_ref, repo, "HEAD"), "failed to lookup HEAD ref")) {
                return -1;
            }

            /* Grab the reference HEAD should be pointing to */
            symbolic_ref = git_reference_symbolic_target(head_ref);
            git_reference_free(head_ref);

            /* Create our master reference on the target OID */
            if (reportError(git_reference_create(&target_ref, repo, symbolic_ref, target_oid, 0, NULL), "failed to create HEAD branch")) {
                return -1;
            }
        } else {
            /* HEAD exists, just lookup and resolve */
            if (reportError(git_repository_head(&target_ref, repo), "failed to get HEAD reference")) {
                return -1;
            }
        }

        /* Lookup the target object */
        if (reportError(git_object_lookup(&target, repo, target_oid, GIT_OBJECT_COMMIT), "failed to lookup target OID")) {
            return -1;
        }

        /* Checkout the result so the workdir is in the expected state */
        ff_checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE;
        if (reportError(git_checkout_tree(repo, target, &ff_checkout_options), "failed to checkout HEAD")) {
            return -1;
        }

        /* Move the target reference to the target OID */
        if (reportError(git_reference_set_target(&new_target_ref, target_ref, target_oid, NULL), "failed to update HEAD")) {
            return -1;
        }

        return 0;
    }
};
