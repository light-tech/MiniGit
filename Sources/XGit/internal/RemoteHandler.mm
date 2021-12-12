//
//  RemoteHandler.mm
//  Single-use struct to perform remote git operations (git clone, git fetch, git push)
//
//  Created by Lightech on 10/24/2048.
//

#import "RemoteProgressReporter.mm"
#import "CheckoutProgressReporter.mm"
#import "GitErrorReporter.mm"

struct RemoteHandler: RemoteProgressReporter, GitErrorReporter, CheckoutProgressReporter {

    RemoteHandler(id<RemoteProgressProtocol> remoteProgress, id<ErrorReceiverProtocol> errorReceiver):
        RemoteProgressReporter(remoteProgress),
        GitErrorReporter(errorReceiver),
        CheckoutProgressReporter(nil) {
    }

    RemoteHandler(id<RemoteProgressProtocol> remoteProgress, id<CheckoutProtocol> checkoutProgress, id<ErrorReceiverProtocol> errorReceiver):
        RemoteProgressReporter(remoteProgress),
        GitErrorReporter(errorReceiver),
        CheckoutProgressReporter(checkoutProgress) {
    }

    int clone(git_repository **repo, const char* remote_url, const char* repo_path) {
        git_clone_options options;
        git_clone_options_init(&options, GIT_CLONE_OPTIONS_VERSION);
        setupCallbacks(&options.fetch_opts.callbacks);
        setupCheckoutCallbacks(&options.checkout_opts);

        auto error = git_clone(repo, remote_url, repo_path, &options);
        reportError(error, "git clone failed");
        onComplete();

        return error;
    }

    // Push all branches and tags to remote
    void push(git_repository *repo, bool force, git_remote *remote) {
        git_push_options options;
        git_push_options_init(&options, GIT_PUSH_OPTIONS_VERSION);
        setupCallbacks(&options.callbacks);

        // Collect local references (branches and tags)
        RefspecHelper refspecHelper(force);
        git_reference_foreach(repo, [](git_reference *reference, void *payload) {
            if (!git_reference_is_remote(reference))
                ((RefspecHelper*)payload)->appendRefspecFor(reference);
            git_reference_free(reference);

            return 0;
        }, &refspecHelper);

        refspecHelper.transferToArray();

        reportError(git_remote_push(remote, &refspecHelper.refspecs, &options), "git push failed");
        onComplete();
    }

    void fetch(git_remote *remote) {
        git_fetch_options options;
        git_fetch_options_init(&options, GIT_FETCH_OPTIONS_VERSION);
        setupCallbacks(&options.callbacks);

        reportError(git_remote_fetch(remote, NULL, &options, NULL), "git fetch failed");

        onComplete();
    }

private:
    struct RefspecList {
        RefspecList(git_reference *ref, bool force) {
            auto refname = git_reference_name(ref);
            auto len = strlen(refname);

            refspec = new char[2 * len + 3];
            if (force) strcpy(refspec, "+");
            strcat(refspec, refname);
            strcat(refspec, ":");
            strcat(refspec, refname);
        }

        ~RefspecList() {
            delete[] refspec;
            delete next;
        }

        char *refspec = NULL;
        RefspecList *next = NULL;
    };

    struct RefspecHelper {
        RefspecHelper(bool force) {
            this->force = force;
        }

        ~RefspecHelper() {
            delete[] refspecs.strings;
            delete refspecs_list; // Note that this will trigger the subsequent nodes deletion!
        }

        RefspecList *refspecs_list = NULL;
        int count = 0;
        bool force;

        git_strarray refspecs = { NULL, 0 };

        void appendRefspecFor(git_reference *ref) {
            auto new_node = new RefspecList(ref, force);
            new_node->next = refspecs_list;
            refspecs_list = new_node;
            count++;
        }

        void transferToArray() {
            if (count <= 0)
                return;

            refspecs.count = count;
            refspecs.strings = new char*[count];
            auto node = refspecs_list;
            auto i = 0;
            while (node != NULL) {
                refspecs.strings[i] = node->refspec;
                // printf("Add push refspec: [%s]\n", refspecs.strings[i]);
                node = node->next;
                i++;
            }
        }
    };
};
