# Contributing to pg_search

First off, if you experience a bug, we welcome you to report it. Please provide a minimal test case showing the code that you ran, its output, and what you expected the output to be instead. If you are able to fix the bug and make a pull request, we are much more likely to get it resolved quickly, but don't feel bad to just report an issue if you don't know how to fix it.

View the [README](./README.md) to see which versions of Ruby, Active Record, and PostgreSQL are supported by pg_search. It can be hard to test against all of the various versions, but please do your best to avoid coding practices that only work in newer versions.

If you have a substantial feature to add, you might want to discuss it first on the [mailing list](https://groups.google.com/forum/#!forum/casecommons-dev). We might have thought hard about it already, and can sometimes help with tips and tricks.

When in doubt, go ahead and make a pull request. If something needs tweaking or rethinking, we will do our best to respond and make that clear.

Don't be discouraged if the maintainers ask you to change your code. We are always appreciative when people work hard to modify our code, but we also have a lot of opinions about coding style and object design.

Our automated tests start by updating all gems to their latest version. This is by design, because we want to be proactive about compatibility with other libraries. You can do the same by running `bundle update` at any time. To test against a specific version of Active Record, you can set the `ACTIVE_RECORD_VERSION` environment variable.

    $ ACTIVE_RECORD_VERSION=5.0 bundle update

Run the tests by running `bundle exec rake`, or `bin/rake` if you use Bundler binstubs. 

Last, but not least, have fun! pg_search is a labor of love.