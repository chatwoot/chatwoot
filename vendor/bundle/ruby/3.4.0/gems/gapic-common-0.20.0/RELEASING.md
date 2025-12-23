# Releasing gapic-common

The Google Ruby GAX project uses [semantic versioning](http://semver.org). Replace the `<prev_version>` and `<version>` placeholders shown in the examples below with the appropriate numbers, e.g. `0.1.0` and `0.2.0`.

After all [pull requests](https://github.com/googleapis/gax-ruby/pulls) for a release have been merged and all [Travis builds](https://travis-ci.org/googleapis/gax-ruby) are green, you may create a release as follows:

1. If you haven't already, switch to the master branch, ensure that you have no changes, and pull from origin.

    ```sh
    $ git checkout master
    $ git status
    $ git pull <remote> master --rebase
    ```

1. Build the gem locally. (Depending on your environment, you may need to `bundle exec` to rake commands; this will be shown.)

    ```sh
    $ bundle exec rake build
    ```

1. Install the gem locally.

    ```sh
    $ bundle exec rake install
    ```

1. Using IRB (not `rake console`!), manually test the gem that you installed in the previous step.

1. Update the `CHANGELOG.md`. Write bullet-point lists of the major and minor changes. You can also add examples, fixes, thank yous, and anything else helpful or relevant. See google-cloud-node [v0.18.0](https://github.com/GoogleCloudPlatform/google-cloud-node/releases/tag/v0.18.0) for an example with all the bells and whistles.

1. Edit `lib/gapic/version.rb` file, changing the value of `VERSION` to your new version number. This repo requires a PR for all changes so doing this in a branch is best.

1. Run the tests, one last time.

    ```sh
    $ bundle update
    $ bundle exec rake spec
    ```

1. Commit your changes. Copy and paste the significant points from your `CHANGELOG.md` edit as the description in your commit message.

    ```sh
    $ git commit -am "Release gapic-common <version> ..."
    ```

1. Tag the version after all changes have been merged.

    ```sh
    $ git tag gapic-common/v<version>
    ```

1. Push the tag.

    ```sh
    $ git push <remote> gapic-common/v<version>
    ```

1. Wait until the [Travis build](https://travis-ci.org/googleapis/gax-ruby) has passed for the tag.

1. Push the gem to [RubyGems.org](https://rubygems.org/gems/google-cloud).

   ```sh
   $ gem push gapic-common-<version>.gem
   ```

1. On the [gax-ruby releases page](https://github.com/googleapis/gax-ruby/releases), click [Draft a new release](https://github.com/googleapis/gax-ruby/releases/new). Complete the form. Include the bullet-point lists of the major and minor changes from the gem's `CHANGELOG.md`. You can also add examples, fixes, thank yous, and anything else helpful or relevant.

1. Click `Publish release`.

1. Wait until the last tag build job has successfully completed on Travis. Then push your commits to the master branch. This will trigger another [Travis](https://travis-ci.org/googleapis/gax-ruby) build on master branch.

    ```sh
    $ git push <remote> master
    ```

High fives all around!