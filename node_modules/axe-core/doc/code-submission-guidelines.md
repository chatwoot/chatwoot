# Code Submission Guidelines

We've enacted standards for commits and pull requests to effectively manage the project over
time. We expect all code contributed to follow these standards. If your code doesn't follow them, we
will kindly ask you to resubmit it in the correct format.

- [Git Commits](#git-commits)
- [Submitting a pull request](#submitting-a-pull-request)
- [Merging a pull request](#merging-a-pull-request)
- [Squashing Commits](#squashing-everything-into-one-commit)

## Git Commits

We follow Angular's code contribution style with precise rules for formatting git commit messages.
This leads to more readable messages that are easy to follow when looking through the project
history. We will also use commit messages to generate the axe Changelog document.

A detailed explanation of Angular's guidelines and conventions can be found [on Google Docs](https://docs.google.com/document/d/1QrDFcIiPjSLDn3EL15IJygNPiHORgU1_OOAqWjiDU5Y/edit#).

### Commit Message Format

Each commit message should consist of a header, a body and a footer. The header has a special format
that includes a type, a scope and a subject. Here's a sample of the format:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Here's an example:

```sh
perf(rule): improve speed of color contrast rules

Use async process to compare elements without UI lockup

Closes issue #1
```

**Note:** We do not link issues to be closed as we have our QA team verify the issue is resolved before closing. Instead use `Closes issue #` to link to the issue the pr resolves but won't close it once merged.

> Commit messages should be 100 characters or less to make them easy to read on Github and
> various git tools.

### How to structure your commits:

#### Type

Must be one of the following:

- **feat:** A new feature
- **fix:** A bug fix
- **docs:** Documentation only changes
- **style:** Changes that do not affect the meaning of the code (white-space, formatting, missing
  semi-colons, etc)
- **refactor:** A code change that neither fixes a bug nor adds a feature
- **perf:** A code change that improves performance
- **test:** Adding missing tests
- **chore:** Changes to the build process or auxiliary tools and libraries such as documentation generation
- **ci:** Changes or fixes to CI configuration such as CircleCI

#### Scope

The scope specifies the place of the commit change in the codebase along with the type. It could
reference a rule, a commons file, or anything really. E.g. `feat(rule)` or
`test(commons/aria)`. It would help us call to out rule changes in our changelog with `rule` used as the scope.

If the scope is too broad to summarize, use the type only and leave off the parentheses. E.g. `type: some subject`. Keep in mind that a long scope often pushes your commit message over 100 characters. Brevity is helpful for everyone!

#### Subject

The subject contains succinct description of the change:

- use the imperative, present tense: "change" not "changed" nor "changes"
- don't capitalize first letter
- no dot (.) at the end

#### Body

Use the imperative, present tense: "change" not "changed" nor "changes", just like the subject. Include the motivation for the change and contrast it with how the code worked before.

#### Footer

Reference any issue that this commit closes with its fully qualified URL to support both Bitbucket and Github.

If needed, the footer should contain any information about [Breaking Changes](https://www.conventionalcommits.org/en/v1.0.0/). Deprecation notices or breaking changes in the Changelog should inform users if they'll need to modify their code after this commit.

A breaking change should be noted with `BREAKING CHANGE:` (all caps, followed by a colon) and a message.

```
feat(rules): remove deprecated rules

BREAKING CHANGE: remove rules: th-has-headers, checkboxgroup, radiogroup
```

## Submitting a pull request

We want to keep our commit log clean by avoiding merge messages in branches. Before submitting a pull request, make sure your branch is up to date with the develop branch by either:

- Pulling from develop before creating your branch
- Doing a rebase from origin/develop (will require a force push **on your branch**)

To rebase from origin/develop if we've pushed changes since you created your branch:

```sh
git checkout your-branch
git fetch
git rebase origin/develop
git push origin head -f
```

## Merging a pull request

If a pull request has many commits (especially if they don't follow our [commit policy](#git-commits)), you'll want to squash them into one clean commit.

In the Github UI, you can use the new [Squash and Merge](https://github.com/blog/2141-squash-your-commits) feature to make this easy. If there are merge conflicts preventing this, either ask the committer to rebase from develop following the [PR submission steps above](#submitting-a-pull-request), or use the manual method below.

To apply a pull request manually, make sure your local develop branch is up to date. Then, create a new branch for that pull request.

Create a temporary, local branch:

```sh
git checkout -b temp-feature-branch
```

Run the following commands to apply all commits from that pull request on top of your branch's local history:

```console
curl -L https://github.com/dequelabs/axe-core/pull/205.patch | git am -3
```

If the merge succeeds, use `git diff origin/develop` to review all the changes that will happen post-merge.

## Squashing everything into one commit

Before merging a pull request with many commits into develop, make sure there is only one commit representing the changes in the pull request, so the git log stays lean. We particularly want to avoid merge messages and vague commits that don't follow our commit policy (like `Merged develop into featurebranch` or `fixed some stuff`).

You can use git's interactive rebase to manipulate, merge, and rename commits in your local history. If these steps are followed, a force push shouldn't be necessary.

**Do not force push to develop or master under any circumstances.**

To interactively rebase all of your commits on top of the latest in develop, run:

```sh
git rebase --interactive origin/develop
```

This brings up an interactive dialog in your text editor. Follow the instructions to squash all of your commits into the top one. Rename the top one.

Once this is done, run `git log` and you will see only one commit after develop, representing everything from the pull request.

Finally, pull from develop with `rebase` to put all of our local commits on top of the latest remote.

```sh
git pull --rebase origin develop
```

You can then push the latest code to develop (note that force push isn't needed if these steps are followed):

```console
git push origin develop
```

## Writing Integration Tests

For each rule, axe-core needs to have integration tests. These tests are located in `tests/integration`. This directory contains two other directories. `rules`, which contains integration tests that can be run on a single page, and `full` which contains tests that can only be tested by running on multiple pages.

Ensure that for each check used in the rule, there is an integration test for both pass and fail results. Integration tests put in `rules` can be described using simple code snippets in an HTML file, and a JSON file that describes the expected outcome. For `full` tests, a complete Jasmine test should be created, including at least one HTML file that has the tested code, and a JS file that has the test statements.
