Contributing to Jbuilder
=====================

[![Build Status](https://github.com/rails/jbuilder/workflows/Ruby%20test/badge.svg)][test]
[![Gem Version](https://badge.fury.io/rb/jbuilder.svg)][gem]
[![Code Climate](https://codeclimate.com/github/rails/jbuilder/badges/gpa.svg)][codeclimate]

[test]: https://github.com/rails/jbuilder/actions?query=branch%3Amaster
[gem]: https://rubygems.org/gems/jbuilder
[codeclimate]: https://codeclimate.com/github/rails/jbuilder

Jbuilder is work of [many contributors](https://github.com/rails/jbuilder/graphs/contributors). You're encouraged to submit [pull requests](https://github.com/rails/jbuilder/pulls), [propose features and discuss issues](https://github.com/rails/jbuilder/issues).

#### Fork the Project

Fork the [project on GitHub](https://github.com/rails/jbuilder) and check out your copy.

```
git clone https://github.com/contributor/jbuilder.git
cd jbuilder
git remote add upstream https://github.com/rails/jbuilder.git
```

#### Create a Topic Branch

Make sure your fork is up-to-date and create a topic branch for your feature or bug fix.

```
git checkout master
git pull upstream master
git checkout -b my-feature-branch
```

#### Bundle Install and Test

Ensure that you can build the project and run tests.

```
bundle install
appraisal install
appraisal rake test
```

#### Write Tests

Try to write a test that reproduces the problem you're trying to fix or describes a feature that you want to build. Add to [test](test).

We definitely appreciate pull requests that highlight or reproduce a problem, even without a fix.

#### Write Code

Implement your feature or bug fix.

Make sure that `appraisal rake test` completes without errors.

#### Write Documentation

Document any external behavior in the [README](README.md).

#### Commit Changes

Make sure git knows your name and email address:

```
git config --global user.name "Your Name"
git config --global user.email "contributor@example.com"
```

Writing good commit logs is important. A commit log should describe what changed and why.

```
git add ...
git commit
```

#### Push

```
git push origin my-feature-branch
```

#### Make a Pull Request

Visit your forked repo and click the 'New pull request' button. Select your feature branch, fill out the form, and click the 'Create pull request' button. Pull requests are usually reviewed within a few days.

#### Rebase

If you've been working on a change for a while, rebase with upstream/master.

```
git fetch upstream
git rebase upstream/master
git push origin my-feature-branch -f
```

#### Check on Your Pull Request

Go back to your pull request after a few minutes and see whether it passed muster with GitHub Actions. Everything should look green, otherwise fix issues and amend your commit as described above.

#### Be Patient

It's likely that your change will not be merged and that the nitpicky maintainers will ask you to do more, or fix seemingly benign problems. Hang in there!

#### Thank You

Please do know that we really appreciate and value your time and work. We love you, really.
