# Releasing Slack-Ruby-Client

There're no hard rules about when to release slack-ruby-client. Release bug fixes frequently, features not so frequently and breaking API changes rarely.

### Release

Run tests, check that all tests succeed locally.

```
bundle install
rake
```

Check that the last build succeeded in [GitHub Actions](https://github.com/slack-ruby/slack-ruby-client/actions) for all supported platforms.

Change "Next" in [CHANGELOG.md](CHANGELOG.md) to the current date.

```
### 0.2.2 (7/10/2015)
```

Remove the line with "Your contribution here.", since there will be no more contributions to this release.

In the "Stable Release" section of the README, change `**next**` to `**stable**` and add the version number so users know that they are reading the documentation for a released version.

```
## Stable Release

You're reading the documentation for the **stable** release of slack-ruby-client, 0.2.2. See [UPGRADING](UPGRADING.md) when upgrading from an older version.
```

Commit your changes.

```
git add README.md CHANGELOG.md
git commit -m "Preparing for release, 0.2.2."
git push origin master
```

Release.

```
$ rake release

slack-ruby-client 0.2.2 built to pkg/slack-ruby-client-0.2.2.gem.
Tagged v0.2.2.
Pushed git commits and tags.
Pushed slack-ruby-client 0.2.2 to rubygems.org.
```

### Prepare for the Next Version

Add the next release to [CHANGELOG.md](CHANGELOG.md).

```
### 0.2.3 (Next)

* Your contribution here.
```

Increment the third version number in [lib/slack/version.rb](lib/slack/version.rb).

Undo your change in README about the stable release.

```
## Stable Release

You're reading the documentation for the **next** release of slack-ruby-client. Please see the documentation for the [last stable release, v0.2.2](https://github.com/slack-ruby/slack-ruby-client/blob/v0.2.2/README.md) unless you're integrating with HEAD. See [UPGRADING](UPGRADING.md) when upgrading from an older version.
```

Commit your changes.

```
git add README.md CHANGELOG.md lib/slack/version.rb
git commit -m "Preparing for next development iteration, 0.2.3."
git push origin master
```
