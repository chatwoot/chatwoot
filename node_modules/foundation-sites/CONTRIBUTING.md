# Foundation Contributing Guidelines

Although Foundation was built and maintained by ZURB for years, it is today a community project. Whether it’s bug fixing, feature development, or contributions to the ecosystem, designers and developers from all over the world help make Foundation the most advanced framework in the world.

## Issues

For **bugs**, **feature requests**, **incorrect documentation** or any problem you have with Foundation, you can open a new issue. If you need help to use Foundation, the [Foundation Forum](https://foundation.zurb.com/forum) would be more appropriate. If you aren't sure if your issue is a bug or not, don’t worry! Post your problem on GitHub and the team will help you along.

Every participant is expected to follow the project's [Code of Conduct](code-of-conduct.md) so please be courteous and respectful.

### Report a bug

1. **Search for similar opened or closed issues** ([link](https://github.com/zurb/foundation-sites/issues?utf8=%E2%9C%93&q=is%3Aissue)).
   It is likely that someone else got the same problem as you before and already reported it.
2. **Make sure of the following:**
   * [ ] There are no [opened or closed issues](https://github.com/zurb/foundation-sites/issues?utf8=%E2%9C%93&q=is%3Aissue) similar to this bug
   * [ ] This is a bug and not a missing feature
   * [ ] This bug comes from Foundation and not the browser or an other library
   * [ ] This bug is still present in the latest Foundation release
3. **Prepare a test case with your bug** ([link](https://codepen.io/ncoden/pen/dQmVgg)).
   Trying to reproduce a bug is often time-consuming. Please isolate your bug in a dedicated test case. The simpler is the test case, the best it is.
4. **Create your issue** ([link](https://github.com/zurb/foundation-sites/issues/new)).
   Please provide a complete description of your bug: What do you expect? What happends instead? Which version of Foundation do you use, which ones are affected by the bug? Keep in mind that someone will spend a lot of time to understand your issue, make the task easy for him/her.

### Request for a new feature
1. **Search for similar opened or closed issues** ([link](https://github.com/zurb/foundation-sites/issues?utf8=%E2%9C%93&q=is%3Aissue)).
   It is likely that someone else needed a similar feature as yours and already requested it.
2. **Make sure of the following:**
   * [ ] There are no [opened or closed issues](https://github.com/zurb/foundation-sites/issues?utf8=%E2%9C%93&q=is%3Aissue) similar to your request
   * [ ] This is a missing feature and not a bug
3. **Prepare a clear use case for the requested feature**.
   This will help you to make sure that this is the feature you want, and us to better understand your needs and how it would benefit to everyone the best way.
4. **Create your issue** ([link](https://github.com/zurb/foundation-sites/issues/new)).
   Please provide a complete description of the feature you want, the use case you prepared will help you for that. After you created your issue, if you feel ready, you can start working on a pull request (please tell us so). See [Contributions](#contributions) below.

## Contributions

All new features and bug fixes should be submitted as pull requests, so the community can review and discuss them. The rule is the same for everyone, for new contributors as for Core Team members.

Before working on a bug fix or a new feature, please make sure of the following:
* [ ] **There is no similar pull request that was rejected or is not merged yet** ([link](https://github.com/zurb/foundation-sites/issues?utf8=%E2%9C%93&q=is%3Apr)).
  Add a comment on this pull request otherwise. Explain us why this pull request is urgent or important to you.
* [ ] **There is an open issue related to this bug or feature**.
  Please create one otherwise. It is often useful to talk about the bug fix or feature and the best way to implement it before working on it. You can skip this step for obvious changes (like typo in the documentation).

After you made these checks, please follow these advices to create your pull requests:
1. **Work on a dedicated Git branch**.
   So you default `develop` branch stay clean and you can open multiple Pull Requests at the same time for various issues. See (2) below for the branch name format.
2. **Use our standard format for branch, commit and pull request names**.
   It must reference the related issue, be written in the "imperative" form (like if it was completing `now the software should...`) and be prefixed by a type (`feat` for new feature, `fix` if you repair something, `docs` for documentation, `refactor` for non-breaking code cleaning, `style` for code formatting, `tests` for unit or visual tests or `chore` for boring day-to-day tasks not affecting the actual code. See the [AngularJs Git Commit Message Convention](https://gist.github.com/stephenparish/9941e89d80e2bc58a153)). For example: `docs: improve Dropdown usage example #123` for commit/pull request names and `docs/dropdown-improve-usage-example-123` for the branch name.
3. **Describe everything you did and why in your commit and pull request body**.
   Even if you already mentionned it in the related issue, please explain what you did and for which reasons. Give references to related issues, comments, test cases or any useful resources.
4. **Provide a clear and readable code**.
   Make sure that the code you changed is consistent across components and that anyone can easily understand its behavior. Split it in abstract functions, avoid code duplication and add comments when needed. You can open a "work-in-progress" pull request (prefix it with "[WIP]") if you need any help with that.
5. **Make sure that everything works and tests pass**.
   You must absolutely check that everything still works after your changes. Please also add tests for features you added or uncovered bugs you fixed. See the [Testing](https://github.com/zurb/foundation-sites#testing) section.
6. **Create your pull request** ([link](https://github.com/zurb/foundation-sites/compare)).
   Make sure it targets the right branch: most often `develop`, unless you provide a fix for an older version and it should be `develop-v...`. Take a look at our [Git Workflow](#git-workflow) below.

When you submit a pull request, @mention a few people you’d like to help you review it. Once those people have signed off on it, the pull request can be merged! Core Team members will handle the merge itself.

## Git Workflow

Foundation uses a Git workflow close to the the successful [GitFlow](http://nvie.com/posts/a-successful-git-branching-model/) branching model, to which we added `develop-v...` and `master-v...` branches to prepare and release patches for older Foundation versions. Most of the time you will not have to care about this workflow and can simply open your pull request on `develop`.

The workflow relies on three branches:

- **`develop`**

  Used to prepare the next minor/major version. It always contains all the new features and bug fixes, and is the most up-to-date version of Foundation. Almost every pull request should be opened on this branch (fixes, features, documentation...). When a new version is released, it is merged on `master`, a dedicated `develop-v...` branch is created, and `develop` now targets the next version.

- **`develop-<version>`**

  Used to prepare patches for previous versions. For example: `develop-v6.5` to prepare the `v6.5.1` release. When a pull request for a bug fix is merged on `develop` and is compatible with supported versions, its commits must be added on the compatible `develop-v...` branches too. If a fix is not compatible with `develop`, a pull request can be opened on the latest compatible and supported `develop-v...` branch. When a new patch is released, it is merged on `master-v...` and `develop-v...` now targets the next patch for this minor version.

- **`master`**

  The stable branch. It only contains the latest stable version released. **Do NOT open pull requests on it**.

- **`master-<version>`**

  The stable branch for previous versions. For example: `master-v6.5` for stable `v6.5.*` releases. **Do NOT open pull requests on it**.

This git workflow was fully adopted as of `v6.5`, so `v6.4` and previous versions are not supported.

## Coding Standards

If you aren't sure how a feature should be implemented, we recommend checking out our [standards document](https://github.com/zurb/foundation-standards), which outlines every aspect of writing framework features, from Sass to JavaScript.

## Core Team

Want to help us making Foundation the best framework ever? The Core Team is inviting active community members to join it. If you want to become a contributor, engage the community on the Foundation Forum, help us close issues on GitHub, and review pull requests from other contributors.

If you’ve made substantial contributions to a Foundation framework and haven’t heard from us yet, you can reach out at foundation@zurb.com.

Contributors are expected to:

- Engage the community on GitHub by responding to and tagging issues.
- Write pull requests to address bugs and feature requests.
- Help in reviewing pull requests from users, contributors, and the Core Team.
- Follow the guidelines outlined in this document.

Here are some example contributions from some of our awesome team members:

- Colin Marshall converted our Sass unit tests to a newer test runner called True.
- Andy Cochran reworked the CSS for button groups to fix issues with stacking and border radii.
- designerno1 developed the Equalize by Row feature for the Equalizer plugin.
