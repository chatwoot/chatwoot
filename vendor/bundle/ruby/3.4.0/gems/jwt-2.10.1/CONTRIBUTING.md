# Contributing to [ruby-jwt](https://github.com/jwt/ruby-jwt)

## Forking the project

Fork the project on GitHub and clone your own fork. Instuctions on forking can be found from the [GitHub Docs](https://docs.github.com/en/get-started/quickstart/fork-a-repo)

```
git clone git@github.com:you/ruby-jwt.git
cd ruby-jwt
git remote add upstream https://github.com/jwt/ruby-jwt
```

## Create a branch for your implementation

Make sure you have the latest upstream main branch of the project.

```
git fetch --all
git checkout main
git rebase upstream/main
git push origin main
git checkout -b fix-a-little-problem
```

## Running the tests and linter

Before you start with your implementation make sure you are able to get a successful test run with the current revision.

The tests are written with rspec and [Appraisal](https://github.com/thoughtbot/appraisal) is used to ensure compatibility with 3rd party dependencies providing cryptographic features.

[Rubocop](https://github.com/rubocop/rubocop) is used to enforce the Ruby style.

To run the complete set of tests and linter run the following

```bash
bundle install
bundle exec appraisal rake test
bundle exec rubocop
```

## Implement your feature

Implement tests and your change. Don't be shy adding a little something in the [README](README.md).
Add a short description of the change in either the `Features` or `Fixes` section in the [CHANGELOG](CHANGELOG.md) file.

The form of the row (You need to return to the row when you know the pull request id)
```
- Fix a little problem [#123](https://github.com/jwt/ruby-jwt/pull/123) - [@you](https://github.com/you).
```

## Push your branch and create a pull request

Before pushing make sure the tests pass and RuboCop is happy.

```
bundle exec appraisal rake test
bundle exec rubocop
git push origin fix-a-little-problem
```

Make a new pull request on the [ruby-jwt project](https://github.com/jwt/ruby-jwt/pulls) with a description what the change is about.

## Update the CHANGELOG, again

Update the [CHANGELOG](CHANGELOG.md) with the pull request id from the previous step.

You can ammend the previous commit with the updated changelog change and force push your branch. The PR will get automatically updated.

```
git add CHANGELOG.md
git commit --amend --no-edit
git push origin fix-a-little-problem -f
```

## Keep an eye on your pull request

A maintainer will review and probably merge you changes when time allows, be patient.

## Keeping your branch up-to-date

It's recommended that you keep your branch up-to-date by rebasing to the upstream main.

```
git fetch upstream
git checkout fix-a-little-problem
git rebase upstream/main
git push origin fix-a-little-problem -f
```

# Releasing a new version

The version is using the [Semantic Versioning](http://semver.org/) and the version is located in the [version.rb](lib/jwt/version.rb) file.
Also update the [CHANGELOG](CHANGELOG.md) to reflect the upcoming version release.

```bash
rake release
```

**If you want a release cut with your PR, please include a version bump according to **
