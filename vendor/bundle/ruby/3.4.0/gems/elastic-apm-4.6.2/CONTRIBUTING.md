# Contributing to the APM Agent

The APM Agent is open source and we love to receive contributions from our community — you!

There are many ways to contribute,
from writing tutorials or blog posts,
improving the documentation,
submitting bug reports and feature requests or writing code.

You can get in touch with us through [Discuss](https://discuss.elastic.co/c/apm),
feedback and ideas are always welcome.

## Code contributions

If you have a bugfix or new feature that you would like to contribute,
please find or open an issue about it first.
Talk about what you would like to do.
It may be that somebody is already working on it,
or that there are particular issues that you should know about before implementing the change.

### Workflow

All feature development and most bug fixes hit the main branch first.
Pull requests should be reviewed by someone with commit access.
Once approved, the author of the pull request,
or reviewer if the author does not have commit access,
should "Squash and merge".

### Testing

To do a full test run, use either `bundle exec rspec` or `rake spec`. Individual specs should also run as expected. The Mongo test needs a Mongo instance running, but will start one itself if Docker is installed.

To test other platform, use the Docker setup and scripts like `spec.sh RUBY_DOCKER_IMAGE FRAMEWORK`.

```sh
$ spec/scripts/spec.sh ruby:2.6 rails-5.2
```

### Releasing

To release a new version:

1. Update `VERSION` in `lib/elastic_apm/version.rb` according to the changes (major, minor, patch).
1. Update `CHANGELOG.md` to reflect the new version – change _Unreleased_ section to _Version (release date)_.
1. For Majors: Add a new row to the EOL table in `docs/upgrading.asciidoc`. The EOL date is the release date plus 18 months.
1. Make a new commit with the changes above, with a message in the style of `vX.X.X`.
1. Run `rake release`. This will...
    1. Tag the current commit as new version.
    2. Push the tag to GitHub.
    3. Build the gem and upload to Rubygems (local user needs to be signed in and authorized.)
1. Run `rake release:update_branch`. This will...
    1. Update `4.x` branch to be at released commit and push it to GitHub.
