//
//  DiffCollector.mm
//  Helper struct to convert from libgit2's git_diff to Objective-C's Diff
//
//  Created by Lightech on 10/24/2048.
//

#include <list>

struct DiffCollector {
    DiffCollector(git_diff * _Nonnull diff) {
        git_diff_foreach(diff,
            collect_diff_file,
            collect_diff_binary_file,
            collect_diff_hunk,
            collect_diff_line,
            this
        );
    }

    NSMutableArray<DiffDelta*>* _Nonnull getDeltas() {
        return convertListToNSMutableArray<Delta,DiffDelta>(deltas);
    }

private:
    template<typename S, typename T>
    static NSMutableArray<T*>* _Nonnull convertListToNSMutableArray(std::list<S> &items) {
        auto result = [[NSMutableArray alloc] init];
        for(auto &item : items) {
            [result addObject :(T*)item.get()];
        }

        return result;
    }

    struct Hunk {
        git_diff_hunk * _Nonnull hunk;
        NSMutableArray<DiffLine*> * _Nonnull lines;

        Hunk(git_diff_hunk * _Nonnull hunk) {
            this->hunk = hunk;
            this->lines = [[NSMutableArray alloc] init];
        }

        void addLine(const git_diff_line * _Nonnull line) {
            [lines addObject :[[DiffLine alloc] init :line]];
        }

        DiffHunk * _Nonnull get() {
            auto result = [[DiffHunk alloc] init :hunk];
            [result setLines :lines];

            return result;
        }
    };

    struct Delta {
        std::list<Hunk> hunks;
        git_diff_delta * _Nonnull delta;

        Delta(git_diff_delta * _Nonnull delta) {
            this->delta = delta;
        }

        void addHunk(const git_diff_hunk * _Nonnull hunk) {
            hunks.push_back(Hunk(const_cast<git_diff_hunk*>(hunk)));
        }

        DiffDelta * _Nonnull get() {
            auto result = [[DiffDelta alloc] init :delta];
            [result setHunks :convertListToNSMutableArray<Hunk,DiffHunk>(hunks)];

            return result;
        }
    };
    
    std::list<Delta> deltas;

    void addDelta(const git_diff_delta * _Nonnull delta) {
        deltas.push_back(Delta(const_cast<git_diff_delta *>(delta)));
    }

    static int collect_diff_file(const git_diff_delta * _Nonnull delta, float progress, void * _Nonnull payload) {
        DiffCollector *state = (DiffCollector*)payload;
        state->addDelta(delta);

        return 0;
    }

    static int collect_diff_binary_file(const git_diff_delta * _Nonnull delta, const git_diff_binary * _Nonnull binary, void * _Nonnull payload) {
        return 0;
    }

    static int collect_diff_hunk(const git_diff_delta * _Nonnull delta, const git_diff_hunk * _Nonnull hunk, void * _Nonnull payload) {
        DiffCollector *state = (DiffCollector*)payload;
        state->deltas.back().addHunk(const_cast<git_diff_hunk*>(hunk));

        return 0;
    }

    static int collect_diff_line(const git_diff_delta * _Nonnull delta, const git_diff_hunk * _Nonnull hunk, const git_diff_line * _Nonnull line, void * _Nonnull payload) {
        DiffCollector *state = (DiffCollector*)payload;
        state->deltas.back().hunks.back().addLine(line);

        return 0;
    }
};
