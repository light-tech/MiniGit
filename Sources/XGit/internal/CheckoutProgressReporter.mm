//
//  CheckoutProgressReporter.mm
//  Base struct for CheckoutHandler and MergeHandler
//
//  Created by Lightech on 10/24/2048.
//

struct CheckoutProgressReporter {
public:
    CheckoutProgressReporter(id<CheckoutProtocol> checkoutProgress) {
        this->checkoutProgress = checkoutProgress;
    }

    void setupCheckoutCallbacks(git_checkout_options *opts) {
        opts->notify_cb = notify_cb;
        opts->notify_payload = this;
        // Temporarily disable the heavy callbacks
        opts->notify_flags = 0; /* GIT_CHECKOUT_NOTIFY_CONFLICT | GIT_CHECKOUT_NOTIFY_DIRTY |
            GIT_CHECKOUT_NOTIFY_UPDATED | GIT_CHECKOUT_NOTIFY_UNTRACKED | GIT_CHECKOUT_NOTIFY_IGNORED; */
        opts->progress_cb = progress_cb;
        opts->progress_payload = this;
        opts->perfdata_cb = perfdata_cb;
        opts->perfdata_payload = this;
    }

private:
    id<CheckoutProtocol> checkoutProgress;

    static int notify_cb(
        git_checkout_notify_t why,
        const char *path,
        const git_diff_file *baseline,
        const git_diff_file *target,
        const git_diff_file *workdir,
        void *payload)
    {
        return 0;
    }

    static void progress_cb(
        const char *path,
        size_t completed_steps,
        size_t total_steps,
        void *payload)
    {
        [((CheckoutProgressReporter*)payload)->checkoutProgress onCheckoutProgress :NSStringFromCString(path) :completed_steps :total_steps];
    }

    static void perfdata_cb(
        const git_checkout_perfdata *perfdata,
        void *payload)
    {
        [((CheckoutProgressReporter*)payload)->checkoutProgress onCheckoutPerfData :perfdata->mkdir_calls :perfdata->stat_calls :perfdata->chmod_calls];
    }
};
