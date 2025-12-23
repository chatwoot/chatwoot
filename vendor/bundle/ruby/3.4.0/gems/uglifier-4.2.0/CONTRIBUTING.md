# Contributing to Uglifier

Any contributions to Uglifier are welcome, whether they are feedback, bug reports, or - even better - pull requests.

## Development

To start working on Uglifier, fork the repo to your own account. [Ruby](https://www.ruby-lang.org), [bundler](http://bundler.io) and [Node.js](http://nodejs.org) are required as dependencies.

Ensure that your local copy is up-to-date before you start working on a feature or a bug fix. You should write any new code in a topic branch.

### Tests

Try to write a test case that reproduces the problem you're trying to fix or describes a feature that you want to build. Tests are located in `spec/` directory.

Tests as a pull request are appreciated even without a fix to highlight or reproduce a problem.

To run tests, first install all project dependencies:

    bundle install

Then run tests using rake:

    bundle exec rake

### Updating UglifyJS and source-map

[UglifyJS](https://github.com/mishoo/UglifyJS2) and [source-map](https://github.com/mozilla/source-map/) are included in the project as Git submodules. To install submodules, run in your terminal

    git submodule update --init

After that, UglifyJS can be updated to a specific version with rake task.

    rake uglifyjs:update VERSION=3.3.4

To compile JS with dependencies, run

    rake uglifyjs:build

You can even write custom patches to UglifyJS in `vendor/uglifyjs` and `vendor/uglifyjs-harmony` directories and compile the bundles JS using the command above. However, for the changes to be releasable, they should be in UglifyJS repository.

To automatically update UglifyJS version and commit changes

    rake uglifyjs VERSION=3.3.4

## Reporting issues

Uglifier uses the [GitHub issue tracker](https://github.com/lautis/uglifier/issues) to track bugs and features. Before submitting a bug report or feature request, check to make sure it hasn't already been submitted. When submitting a bug report, please include a Gist that includes a stack trace and any details that may be necessary to reproduce the bug, including your gem version, Ruby version, and **ExecJS runtime**. Ideally, a bug report should include a pull request with failing specs.
