<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [How to contribute:](#how-to-contribute)
  - [Bug reports / Issues](#bug-reports--issues)
  - [Code](#code)
    - [Commit Messages](#commit-messages)
    - [About Pull Requests (PR's)](#about-pull-requests-prs)
  - [Documentation](#documentation)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# How to contribute:

## Bug reports / Issues

  * Is something broken or not working as expected? Check for an existing issue or [create a new one](https://github.com/mbleigh/acts-as-taggable-on/issues/new)
  * IMPORTANT: Include the version of the gem, if you've install from git, what Ruby and Rails you are running, etc.

## Code

1. [Fork and clone the repo](https://help.github.com/articles/fork-a-repo)
2. Install the gem dependencies: `bundle install`
3. Make the changes you want and back them up with tests.
  * [Run the tests](https://github.com/mbleigh/acts-as-taggable-on#testing) (`bundle exec rake spec`)
4. Update the CHANGELOG.md file with your changes and give yourself credit
5. Commit and create a pull request with details as to what has been changed and why
  * Use well-described, small (atomic) commits.
  * Include links to any relevant github issues.
  * *Don't* change the VERSION file.
6. Extra Credit: [Confirm it runs and tests pass on the rubies specified in the Github Actions config](.github/workflows/spec.yml). I will otherwise confirm it runs on these.

How I handle pull requests:

* If the tests pass and the pull request looks good, I will merge it.
* If the pull request needs to be changed,
  * you can change it by updating the branch you generated the pull request from
    * either by adding more commits, or
    * by force pushing to it
  * I can make any changes myself and manually merge the code in.

### Commit Messages

* [A Note About Git Commit Messages](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
* [http://stopwritingramblingcommitmessages.com/](http://stopwritingramblingcommitmessages.com/)
* [ThoughtBot style guide](https://github.com/thoughtbot/guides/tree/main/git)

### About Pull Requests (PR's)

* [All Your Open Source Code Are Belong To Us](http://www.benjaminfleischer.com/2013/07/30/all-your-open-source-code-are-belong-to-us/)
* [Using Pull Requests](https://help.github.com/articles/using-pull-requests)
* [Github pull requests made easy](https://www.element84.com/blog/github-pull-requests-made-easy)

## Documentation

* Update the wiki
