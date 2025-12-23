<p align="center">
    <a href="http://oauth.net/core/1.0/" target="_blank" rel="noopener">
      <img width="124px" src="https://github.com/oauth-xx/oauth-ruby/raw/main/docs/images/logo/Oauth_logo.svg?raw=true" alt="OAuth 1.0 Logo by Chris Messina, CC BY-SA 3.0, via Wikimedia Commons">
    </a>
    <a href="https://www.ruby-lang.org/" target="_blank" rel="noopener">
      <img width="124px" src="https://github.com/oauth-xx/oauth-ruby/raw/main/docs/images/logo/ruby-logo-198px.svg?raw=true" alt="Yukihiro Matsumoto, Ruby Visual Identity Team, CC BY-SA 2.5">
    </a>
</p>

# OAuth::TTY

A TTY Command Line Interface for interacting with OAuth 1.0 services.

This library was written originally by [Thiago Pinto](https://github.com/thiagopintodev) in 2016 and bundled with the oauth gem.
It was extracted into a separate library by [Peter Boling](https://railsbling.com) in 2022 as part of the move to a stable version 1.0 for the oauth gem.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add oauth-tty

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install oauth-tty

NOTE: You might see a warning like:
```
oauth-tty's executable "oauth" conflicts with oauth
Overwrite the executable? [yN]  y
```
The `oauth` executable from this gem *is* the extracted and repackaged executable from the `oauth` gem, so you *should* overwrite it.

## Usage

In a shell run `oauth` to start the console.

For now, please see the tests for other usage.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://gitlab.com/oauth-xx/oauth-tty/-/issues](https://gitlab.com/oauth-xx/oauth-tty/-/issues). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://gitlab.com/oauth-xx/oauth-tty/-/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OAuth::TTY project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://gitlab.com/oauth-xx/oauth-tty/-/blob/main/CODE_OF_CONDUCT.md).
