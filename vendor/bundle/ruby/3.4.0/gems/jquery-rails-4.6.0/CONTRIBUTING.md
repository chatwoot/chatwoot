Contributing to jquery-rails
=====================

[![Build Status](https://travis-ci.org/rails/jquery-rails.svg?branch=master)](https://travis-ci.org/rails/jquery-rails)

jquery-rails is work of [many contributors](https://github.com/rails/jquery-rails/graphs/contributors). You're encouraged to submit [pull requests](https://github.com/rails/jquery-rails/pulls), [propose features and discuss issues](https://github.com/rails/jquery-rails/issues).

#### Updating jQuery

If the jquery or jquery-ui scripts are outdated (i.e. maybe a new version of jquery was released yesterday), feel free to open an issue and prod us to get that thing updated. However, for security reasons, we won't be accepting pull requests with updated jquery or jquery-ui scripts.

#### Changes to jquery_ujs.js

**If it's an issue pertaining to the jquery-ujs javascript, please
report it to the [rails/jquery-ujs project](https://github.com/rails/jquery-ujs/issues).**

#### Fork the Project

Fork the [project on Github](https://github.com/rails/jquery-rails) and check out your copy.

```
git clone https://github.com/contributor/jquery-rails.git
cd jquery-rails
git remote add upstream https://github.com/rails/jquery-rails.git
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
bundle exec rake test
```

#### Write Tests

Try to write a test that reproduces the problem you're trying to fix or describes a feature that you want to build. Add to [test](test).

#### Testing

This is a gem that simply includes jQuery and jQuery UJS into the Rails
asset pipeline. The asset pipeline functionality is well tested within the
Rails framework. And jQuery and jQuery UJS each have their own extensive
test suites. Thus, there's not a lot to actually test here.

That being said, we do have a few integration-level tests to make sure
everything is being included and basic UJS functionality works within a
sample Rails app.

If you're making changes to the actual gem, run the tests as follows:

1. Checkout the demo Rails app: `git clone git://github.com/JangoSteve/Rails-jQuery-Demo.git`

2. Install the gems: `bundle install`

3. Change the jquery-rails gem in the Gemfile to use your local
version of the gem with your updates: `gem 'jquery-rails', :path => '../path/to/jquery-rails'`

4. Update your bundled jquery-rails gem: `bundle update jquery-rails`

5. Run the tests: `bundle exec rspec spec/`

We definitely appreciate pull requests that highlight or reproduce a problem, even without a fix.

#### Write Code

Implement your feature or bug fix.

Make sure that `bundle exec rake test` completes without errors.

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

Go to https://github.com/contributor/jquery-rails and select your feature branch. Click the 'Pull Request' button and fill out the form. Pull requests are usually reviewed within a few days.

#### Rebase

If you've been working on a change for a while, rebase with upstream/master.

```
git fetch upstream
git rebase upstream/master
git push origin my-feature-branch -f
```

#### Check on Your Pull Request

Go back to your pull request after a few minutes and see whether it passed muster with Travis-CI. Everything should look green, otherwise fix issues and amend your commit as described above.

#### Be Patient

It's likely that your change will not be merged and that the nitpicky maintainers will ask you to do more, or fix seemingly benign problems. Hang on there!

#### Thank You

Please do know that we really appreciate and value your time and work. We love you, really.
