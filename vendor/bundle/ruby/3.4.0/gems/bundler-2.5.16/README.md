[![Version ](https://img.shields.io/gem/v/bundler.svg?style=flat)](https://rubygems.org/gems/bundler)

# Bundler: a gem to bundle gems

Bundler makes sure Ruby applications run the same code on every machine.

It does this by managing the gems that the application depends on. Given a list of gems, it can automatically download and install those gems, as well as any other gems needed by the gems that are listed. Before installing gems, it checks the versions of every gem to make sure that they are compatible, and can all be loaded at the same time. After the gems have been installed, Bundler can help you update some or all of them when new versions become available. Finally, it records the exact versions that have been installed, so that others can install the exact same gems.

### Installation and usage

To install (or update to the latest version):

```
gem install bundler
```

To install a prerelease version (if one is available), run `gem install bundler --pre`. To uninstall Bundler, run `gem uninstall bundler`.

Bundler is most commonly used to manage your application's dependencies. For example, these commands will allow you to use Bundler to manage the `rspec` gem for your application:

```
bundle init
bundle add rspec
bundle install
bundle exec rspec
```

See [bundler.io](https://bundler.io) for the full documentation.

### Troubleshooting

For help with common problems, see [TROUBLESHOOTING](doc/TROUBLESHOOTING.md).

Still stuck? Try [filing an issue](https://github.com/rubygems/rubygems/issues/new?labels=Bundler&template=bundler-related-issue.md).

### Other questions

To see what has changed in recent versions of Bundler, see the [CHANGELOG](CHANGELOG.md).

To get in touch with the Bundler core team and other Bundler users, please join [the Bundler slack](https://join.slack.com/t/bundler/shared_invite/zt-1rrsuuv3m-OmXKWQf8K6iSla4~F1DBjQ).

### Contributing

If you'd like to contribute to Bundler, that's awesome, and we <3 you. We've put together [the Bundler contributor guide](https://github.com/rubygems/rubygems/blob/master/bundler/doc/contributing/README.md) with all of the information you need to get started.

If you'd like to request a substantial change to Bundler or its documentation, refer to the [Bundler RFC process](https://github.com/rubygems/rfcs) for more information.

### Supporting

RubyGems is managed by [Ruby Central](https://rubycentral.org), a non-profit organization that supports the Ruby community through projects like this one, as well as [RubyConf](https://rubyconf.org), [RailsConf](https://railsconf.org), and [RubyGems.org](https://rubygems.org). You can support Ruby Central by attending or [sponsoring](sponsors@rubycentral.org) a conference, or by [joining as a supporting member](https://rubycentral.org/#/portal/signup).

### Code of Conduct

Everyone interacting in the Bundler project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [Bundler code of conduct](https://github.com/rubygems/rubygems/blob/master/CODE_OF_CONDUCT.md).

### License

Bundler is available under an [MIT License](https://github.com/rubygems/rubygems/blob/master/bundler/LICENSE.md).
