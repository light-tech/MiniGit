//
//  RemoteProgressReporter.mm
//  Base struct for remote progress handling
//
//  Created by Lightech on 10/24/2048.
//

struct RemoteProgressReporter {
    RemoteProgressReporter(id<RemoteProgressProtocol> remoteProgress) {
        this->remoteProgress = remoteProgress;
    }

    void setupCallbacks(git_remote_callbacks* callbacks) {
        callbacks->sideband_progress = sideband_progress;
        // callbacks->certificate_check;
        callbacks->credentials = credentials;
        callbacks->transfer_progress = transfer_progress;
        callbacks->update_tips = update_tips;
        callbacks->pack_progress = pack_progress;
        callbacks->push_transfer_progress = push_transfer_progress;
        callbacks->push_update_reference = push_update_reference;
        callbacks->push_negotiation = push_negotiation;
        callbacks->transport = NULL;
        // callbacks->resolve_url = resolve_url;
        callbacks->payload = this;
    }

    void onComplete() {
        [remoteProgress onComplete];
    }

private:
    id<RemoteProgressProtocol> remoteProgress;

    static int sideband_progress(const char *str, int len, void *payload) {
        NSString *msg = NSStringFromBuffer(str, len);
        [((RemoteProgressReporter*)payload)->remoteProgress onSidebandProgress :msg];

        return 0;
    }

    static int credentials(git_credential **out, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload) {
        id<CredentialProtocol> cred = [((RemoteProgressReporter*)payload)->remoteProgress getCredential];

        if (!cred) {
            // RemoteProgressProtocol does not supply a credential
            // Raise an error here since we need a credential
            // Ideally, we should have access to error reporter, but since we don't, we add the
            // mustSupplyCredential temporarily.
            [((RemoteProgressReporter*)payload)->remoteProgress mustSupplyCredential];
            return -1;
        }

        if ([cred isUserNamePasswordAuthenticationMethod]) {
            auto username = [[cred getUserName] UTF8String];
            auto password = [[cred getPassword] UTF8String];

            // Note that we cannot create git_credential once and for all
            // Since it will be FREED by the push/fetch and so will cause a crash
            // The problem is that some operations (push) requires authentication for 2-3 times.
            // If the credentials do not work, we could run into an infinite loop here!
            auto error = git_credential_userpass_plaintext_new(out, username, password);

            return error;
        } else {
            // TODO Support SSH
            printf("Unsupported credential");
            return -1;
        }
    }

    static int transfer_progress(const git_indexer_progress *stats, void *payload) {
        [((RemoteProgressReporter*)payload)->remoteProgress onTransferProgress
                        :stats->total_objects
                        :stats->indexed_objects
                        :stats->received_objects
                        :stats->local_objects
                        :stats->total_deltas
                        :stats->indexed_deltas
                        :stats->received_bytes];

        return 0;
    }

    static int update_tips(const char *refname, const git_oid *a, const git_oid *b, void *data) {
        [((RemoteProgressReporter*)data)->remoteProgress onUpdateTips
                        :NSStringFromCString(refname)
                        :[[OID alloc] init :a]
                        :[[OID alloc] init :b]];

        return 0;
    }

    static int pack_progress(int stage, uint32_t current, uint32_t total, void *payload) {
        [((RemoteProgressReporter*)payload)->remoteProgress onPackProgress :stage :current :total];

        return 0;
    }

    static int push_transfer_progress(unsigned int current, unsigned int total, size_t bytes, void* payload) {
        [((RemoteProgressReporter*)payload)->remoteProgress onPushTransferProgress :current :total :bytes];

        return 0;
    }

    static int push_update_reference(const char *refname, const char *status, void *data) {
        [((RemoteProgressReporter*)data)->remoteProgress onPushUpdateReference
                        :NSStringFromCString(refname)
                        :NSStringFromCString(status)];

        return 0;
    }

    static int push_negotiation(const git_push_update **updates, size_t len, void *payload) {
        NSMutableArray<PushUpdate*> *push_updates = [[NSMutableArray alloc] init];
        for(int i = 0; i < len; i++) {
            [push_updates addObject :[[PushUpdate alloc] init :updates[i]]];
        }
        [((RemoteProgressReporter*)payload)->remoteProgress onPushNegotiation :push_updates];

        return 0;
    }

    static int resolve_url(git_buf *url_resolved, const char *url, int direction, void *payload) {
        return 0;
    }
};
