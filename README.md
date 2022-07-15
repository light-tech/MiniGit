### MiniGit

Minimal Swift package to provide most common Git functionalities.

Check out [OmiGit](https://apps.apple.com/us/app/omigit/id1597699768) on the App Store for illustration of the package's features. See also [our sample app](https://github.com/light-tech/MiniGit-SampleApp).

While `SwiftGit2` already provides a Swift binding for `libgit2`, it is lacking some crucial features such as `git push`.
In an attempt to implement those, we come to believe it is best to write C code in C/C++ instead of [Swift's syntax for C code](https://github.com/apple/swift/blob/main/docs/HowSwiftImportsCAPIs.md) so that it will be much easier for future development and maintenance.

Thankfully, Apple's Swift Package Manager now supported Swift modules written in Objective-C.
This leads us to make a new Swift package `MiniGit` to provide the bare minimal Git functionality written in Objective-C that could be used in Swift-based projects.
(But really it is just C++ mostly: Objective-C was to establish an interface to the Swift side.)

There are two libraries (_modules_, to be precise) in this Swift package:
 * __XGit__: The eXtensible Git module, written in Objective-C, whose classes could be subclassed to provide extra functionalities desired. All interactions with `libgit2` happen here.
 * __MiniGit__: The UI extension of XGit whose classes extend those of XGit and conform to `Identifiable` and `ObservableObject` to support SwiftUI binding.

# Features

Provide key features from the following commonly used `git` commands:

 * `git init`
 * `git clone`
 * `git status`
 * `git diff`
 * `git add`
 * `git restore --staged`
 * `git commit`
 * `git log`
 * `git branch`
 * `git push`
 * `git fetch`
 * `git merge`
 * `git checkout`
 * `git reset`

There is one notable behavioral differece in the `merge` implementation: **We do not create the merge commit automatically.**
After a merge, the client must do that to clear the MERGE state (after resolving all conflicts) or reset to discard the unwanted merge.
This allows user to fill in the commit message and update user name/email in the UI if necessary since we do not support amend last commit at this point.

# Usage

If you use both XGit and MiniGit i.e. add both to your project's target **Frameworks, Libraries and Embedded Contents**, then you are good to go.

If you use the core module XGit by itself only, then you must add the `libgit2.xcframework`, `libz.tbd` and `libiconv.tbd` to your project's target **Frameworks, Libraries and Embedded Contents**.

When building for real iPhone, disable Bitcode.

See [our sample app](https://github.com/light-tech/MiniGit-SampleApp) for a starting point.

# Design

XGit was designed with SwiftUI interoperability in mind.

The module single entry point is the `Repository` class.
Its methods pretty much follows the corresponding `git` command, except for `git init` since `init` has dedicated meaning in Objective-C.
There is only one constructor with a supplied repository path which does not open the repository automatically.
The constructor does not fail so one checks `exists` method after `open` to see if there is really a repository there.
To allow data classes to be extensible and interoperate with SwiftUI, we make use of the factory methods: Subclass of `Repository` can override `makeCommit` to return the desired instance of a `Commit` subclass.

The majority of other classes are designed as wrapper for their `libgit2` C counterparts: We essentially keep a private pointer to the C struct and free it automatically on `deinit`.
For example, we have class `Commit` as wrappper for libgit2's `git_commit` to expose the latter's key information (author, time, OID, ...) as Objective-C's properties.
Notable exceptions are the `Diff`-related, `OID` and `GitError` classes which are meant to be used as data-converted value `struct`s (immutable state) rather than actual classes.

We also use `@protocol` such as `StatusProtocol`, `CheckoutProtocol`, `MergeProtocol` to capture complicated returned results such as `git status`, to report the progress of operations and to report errors.
For example: In `git status` implementation, instead of returning a `Status` object in Objective-C, we take a `StatusProtocol` as input through which we report the staged changes, unstaged changes, etc.
This is to make it easier to use in SwiftUI: Swift client could then implement the `Status` class conforming to `StatusProtocol` and `ObservableObject` so that the status could be bound to a SwiftUI `View`.

# Implementation

Most functionalities are implemented by literally __copy and paste__ libgit2's sample codes.
However, to avoid usage of `goto` statements (to perform clean-up, deallocate objects upon failure), we use single-use C++ struct and make use of the fact that as an object goes out of scope, it gets destroyed automatically.

# Source structure

 * `include/`: Module export, umbrella header `Repository.h` and the supplementary headers.
 * `internal/`: Internal implementation, excluded from the package, as they are `#import`ed directly into the single main implementation file `Repository.mm`.
 * `Repository.mm`: Our main implementation file.

# License

Same as [libgit2](https://github.com/libgit2/libgit2).
