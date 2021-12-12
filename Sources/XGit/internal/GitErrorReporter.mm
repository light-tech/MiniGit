//
//  GitErrorReporter.mm
//  Base struct for various *Handler structs
//
//  Created by Lightech on 10/24/2048.
//

#import "ErrorReceiverProtocol.h"
#import "GitError.mm"

struct GitErrorReporter {

    GitErrorReporter(id<ErrorReceiverProtocol> receiver) {
        this->receiver = receiver;
    }

    /**
     * Check if there is a Git error and report it
     *
     * @param errorCode Error code of a libgit2 function
     * @param message Extra developer message for debugging
     * @return `true` if there is an error
     */
    bool reportError(int errorCode, const char *message)
    {
        if (!errorCode)
            return false;

        GitError *ge = nil;

        const git_error *err = git_error_last();
        if (err != NULL) {
            ge = [[GitError alloc] init :err];
        }

        [receiver onError :errorCode :ge :NSStringFromCString(message)];

        return true;
    }

private:
    id<ErrorReceiverProtocol> receiver;
};
