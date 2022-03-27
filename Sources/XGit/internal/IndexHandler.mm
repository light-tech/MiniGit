//
//  MergeHandler.mm
//  Single-use struct to perform operations with index such as stage/unstage files and creating a new commit
//
//  Created by Lightech on 10/24/2048.
//

#import "GitErrorReporter.mm"

struct IndexHandler: GitErrorReporter {

    IndexHandler(id<ErrorReceiverProtocol> errorReceiver):
		GitErrorReporter(errorReceiver) {
    }

    ~IndexHandler() {
        git_index_free(index);

        // Extra clean up for unstage method
        git_reference_free(head_ref);
        git_object_free(head_commit);

        // Extra clean up for commit method
        git_tree_free(tree);
        git_signature_free(signature);
        git_reference_free(ref);
        git_object_free(parent);
        if (parents_count > 1) {
            git_commit_free(parents[1]);
        }
    }

    git_index *index = NULL;

    static int print_matched_cb(const char *path, const char *matched_pathspec, void *payload){
        return 0;
    }

    void stage(git_repository *repo, const char* path) {
        if (reportError(git_repository_index(&index, repo), "Cannot open index"))
            return;

        git_strarray pathspec = { (char**)(&path), 1 };
        if (reportError(git_index_add_all(index, &pathspec, 0, print_matched_cb, this), "Fail to stage path"))
            return;

        reportError(git_index_write(index), "Cannot write index");
    }

    // Used in unstage
    git_reference *head_ref = NULL;
    git_object *head_commit = NULL;

    void unstage(git_repository *repo, const char* path) {
        if (reportError(git_repository_index(&index, repo), "Cannot open index"))
            return;

        if (git_repository_head(&head_ref, repo) == 0) {
            if (reportError(git_reference_peel(&head_commit, head_ref, GIT_OBJECT_COMMIT), "Cannot peel HEAD to a tree; HEAD might be corrupted!"))
                return;
        }

        git_strarray pathspec = { (char**)(&path), 1 };
        if (reportError(git_reset_default(repo, head_commit, &pathspec), "git reset failed"))
            return;

        reportError(git_index_write(index), "Cannot write index");
    }

    // Used in commit method
    git_tree *tree = NULL;
    git_object *parent = NULL;
    git_reference *ref = NULL;
    git_signature *signature = NULL;

    // In that case, the first parent should be HEAD and the second
    // parent is in MERGE_HEAD. Note that octopus merge (more than
    // 2 trees) with conflicts never work.
    git_commit *parents[2] = { NULL, NULL }; // Maximum 2 parents HEAD and MERGE_HEAD
    int parents_count = 0;

    void commit(git_repository *repo, const char* message) {
        git_oid commit_oid, tree_oid;
        int error;

        if (reportError(git_signature_default(&signature, repo), "Error creating signature"))
            return;

        error = git_revparse_ext(&parent, &ref, repo, "HEAD");
        if (error == GIT_ENOTFOUND) {
            // printf("HEAD not found. Creating first commit\n");
            error = 0;
        } else if (reportError(error, "Error parsing HEAD reference; repo is probably corrupted")) {
            return;
        }

        if (reportError(git_repository_index(&index, repo), "Cannot open index"))
            return;

        if (reportError(git_index_write_tree(&tree_oid, index), "Could not write index tree"))
            return;

        if (reportError(git_index_write(index), "Cannot write index"))
            return;

        if (reportError(git_tree_lookup(&tree, repo, &tree_oid), "Error looking up tree"))
            return;

        if (parent != NULL) {
            parents[0] = (git_commit*)parent; // HEAD
            parents_count = 1;
        }

        int state = git_repository_state(repo);
        if (state == GIT_REPOSITORY_STATE_MERGE) {
            // If we are in MERGE state, this cannot be the initial commit
            git_oid merge_oid;
            if (reportError(git_reference_name_to_id(&merge_oid, repo, "MERGE_HEAD"), "Error determining MERGE_HEAD"))
                return;
            if (reportError(git_commit_lookup(&parents[1], repo, &merge_oid), "Invalid MERGE_HEAD target"))
                return;
            parents_count++;
        } else if (state != GIT_REPOSITORY_STATE_NONE) {
            // TODO Cannot commit?
        }

        if (reportError(git_commit_create(&commit_oid, repo, "HEAD", signature, signature, NULL, message, tree,
                                        parents_count, (const git_commit **)parents),
                        "Commit: Error creating commit"))
            return;

        if (parents_count > 1) {
            git_repository_state_cleanup(repo); // Clean up MERGE state if applicable
        }
    }
};
