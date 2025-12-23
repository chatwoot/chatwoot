# Contributing to Rack

Rack is work of [hundreds of
contributors](https://github.com/rack/rack/graphs/contributors). You're
encouraged to submit [pull requests](https://github.com/rack/rack/pulls) and
[propose features and discuss issues](https://github.com/rack/rack/issues).

## Backports

Only security patches are ideal for backporting to non-main release versions. If
you're not sure if your bug fix is backportable, you should open a discussion to
discuss it first.

The [Security Policy] documents which release versions will receive security
backports.

## Fork the Project

Fork the [project on GitHub](https://github.com/rack/rack) and check out your
copy.

```
git clone https://github.com/(your-github-username)/rack.git
cd rack
git remote add upstream https://github.com/rack/rack.git
```

## Create a Topic Branch

Make sure your fork is up-to-date and create a topic branch for your feature or
bug fix.

```
git checkout main
git pull upstream main
git checkout -b my-feature-branch
```

## Running All Tests

Install all dependencies.

```
bundle install
```

Run all tests.

```
rake test
```

## Write Tests

Try to write a test that reproduces the problem you're trying to fix or
describes a feature that you want to build.

We definitely appreciate pull requests that highlight or reproduce a problem,
even without a fix.

## Write Code

Implement your feature or bug fix.

Make sure that all tests pass:

```
bundle exec rake test
```

## Write Documentation

Document any external behavior in the [README](README.md).

## Update Changelog

Add a line to [CHANGELOG](CHANGELOG.md).

## Commit Changes

Make sure git knows your name and email address:

```
git config --global user.name "Your Name"
git config --global user.email "contributor@example.com"
```

Writing good commit logs is important. A commit log should describe what changed
and why.

```
git add ...
git commit
```

## Push

```
git push origin my-feature-branch
```

## Make a Pull Request

Go to your fork of rack on GitHub and select your feature branch. Click the
'Pull Request' button and fill out the form. Pull requests are usually
reviewed within a few days.

## Rebase

If you've been working on a change for a while, rebase with upstream/main.

```
git fetch upstream
git rebase upstream/main
git push origin my-feature-branch -f
```

## Make Required Changes

Amend your previous commit and force push the changes.

```
git commit --amend
git push origin my-feature-branch -f
```

## Check on Your Pull Request

Go back to your pull request after a few minutes and see whether it passed
tests with GitHub Actions. Everything should look green, otherwise fix issues and
amend your commit as described above.

## Be Patient

It's likely that your change will not be merged and that the nitpicky
maintainers will ask you to do more, or fix seemingly benign problems. Hang in
there!

## Thank You

Please do know that we really appreciate and value your time and work. We love
you, really.

[Security Policy]: SECURITY.md
