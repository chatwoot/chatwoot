# Contributing to email-provider-info

👍🎉 First off, thanks for taking the time to contribute! 🎉👍

The following is a set of guidelines for contributing to this project. These are
mostly guidelines, not rules. Use your best judgment, and feel free to propose
changes to this document in a pull request.

## Code of Conduct

Everyone interacting in this project's codebases, issue trackers, chat rooms and
mailing lists is expected to follow the
[code of conduct](https://github.com/fnando/email-provider-info/blob/main/CODE_OF_CONDUCT.md).

## Reporting bugs

This section guides you through submitting a bug report. Following these
guidelines helps maintainers and the community understand your report, reproduce
the behavior, and find related reports.

- Before creating bug reports, please check the open issues; somebody may
  already have submitted something similar, and you may not need to create a new
  one.
- When you are creating a bug report, please include as many details as
  possible, with an example reproducing the issue.

## Contributing with code

Before making any radicals changes, please make sure you discuss your intention
by
[opening an issue on Github](https://github.com/fnando/email-provider-info/issues).

When you're ready to make your pull request, follow checklist below to make sure
your contribution is according to how this project works.

1. [Fork](https://help.github.com/forking/) email-provider-info
2. Create a topic branch - `git checkout -b my_branch`
3. Make your changes using [descriptive commit messages](#commit-messages)
4. Update CHANGELOG.md describing your changes by adding an entry to the
   "Unreleased" section. If this section is not available, create one right
   before the last version.
5. Push to your branch - `git push origin my_branch`
6. [Create a pull request](https://help.github.com/articles/creating-a-pull-request)
7. That's it!

## Styleguides

### Commit messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

### Changelog

- Add a message describing your changes to the "Unreleased" section. The
  changelog message should follow the same style as the commit message.
- Prefix your message with one of the following:
  - `[Added]` for new features.
  - `[Changed]` for changes in existing functionality.
  - `[Deprecated]` for soon-to-be removed features.
  - `[Removed]` for now removed features.
  - `[Fixed]` for any bug fixes.
  - `[Security]` in case of vulnerabilities.

### Ruby code

- This project uses [Rubocop](https://rubocop.org) to enforce code style. Before
  submitting your changes, make sure your tests are passing and code conforms to
  the expected style by running `rake`.
- Do not change the library version. This will be done by the maintainer
  whenever a new version is about to be released.

### JavaScript code

- This project uses [ESLint](https://eslint.org) to enforce code style. Before
  submitting your changes, make sure your tests are passing and code conforms to
  the expected style by running `yarn test:ci`.
- Do not change the library version. This will be done by the maintainer
  whenever a new version is about to be released.
