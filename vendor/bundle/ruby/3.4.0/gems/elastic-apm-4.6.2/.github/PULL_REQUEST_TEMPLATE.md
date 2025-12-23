<!--
A few suggestions about filling out this PR

1. Use a descriptive title for the PR.
2. If this pull request is work in progress, create a draft PR instead of prefixing the title with WIP.
3. Please label this PR at least one of the following labels, depending on the scope of your change:
- feature request, which adds new behavior
- bug fix
- enhancement, which modifies existing behavior
- breaking change
4. Remove those recommended/optional sections if you don't need them. Only "What does this PR do", "Why is it important?" and "Checklist" are mandatory.
5. Generally, we require that you test any code you are adding or modifying.
Once your changes are ready to submit for review:
6. Submit the pull request: Push your local changes to your forked copy of the repository and submit a pull request (https://help.github.com/articles/using-pull-requests).
7. Please be patient. We might not be able to review your code as fast as we would like to, but we'll do our best to dedicate to it the attention it deserves. Your effort is much appreciated!
-->

## What does this pull request do?

<!--
Use this space to describe what the proposed code _does_, ie. what precisely will be done differently from this change.
-->

## Why is it important?

<!--
Optionally provide an explanation of why this is important.
-->

## Checklist
<!--
Add a checklist of things that are required to be reviewed in order to have the PR approved

List here all the items you have verified BEFORE sending this PR. Please DO NOT remove any item, striking through those that do not apply. (Just in case, strikethrough uses two tildes. ~~Scratch this.~~)
-->

- [ ] I have signed the [Contributor License Agreement](https://www.elastic.co/contributor-agreement/).
- [ ] My code follows the style guidelines of this project (See `.rubocop.yml`)
- [ ] I have rebased my changes on top of the latest main branch
<!--
Update your local repository with the most recent code from the main repo, and rebase your branch on top of the latest main branch. We prefer your initial changes to be squashed into a single commit. Later, if we ask you to make changes, add them as separate commits. This makes them easier to review.
-->
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing [**unit** tests](https://github.com/elastic/apm-agent-ruby/blob/main/CONTRIBUTING.md#testing) pass locally with my changes
<!--
Run the test suite to make sure that nothing is broken. See https://github.com/elastic/apm-agent-ruby/blob/main/CONTRIBUTING.md#testing for details.
-->
- [ ] I have made corresponding changes to the documentation
- [ ] I have updated [CHANGELOG.asciidoc](CHANGELOG.asciidoc)
- [ ] I have updated [supported-technologies.asciidoc](docs/supported-technologies.asciidoc)
- [ ] Added an API method or config option? Document in which version this will be introduced

## Related issues
<!--
Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it.
- Closes #ISSUE_ID
- Relates #ISSUE_ID
- Requires #ISSUE_ID
- Superseds #ISSUE_ID
-->
