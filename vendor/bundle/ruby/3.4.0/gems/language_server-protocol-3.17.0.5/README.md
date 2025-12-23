# LanguageServer::Protocol

A Language Server Protocol SDK for Ruby.

[![Gem Version](https://badge.fury.io/rb/language_server-protocol.svg)](https://badge.fury.io/rb/language_server-protocol)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'language_server-protocol'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install language_server-protocol

## Usage

Currently, this gem supports only stdio as transport layer out of box.

```ruby
require "language_server-protocol"

LSP = LanguageServer::Protocol
writer = LSP::Transport::Stdio::Writer.new
reader = LSP::Transport::Stdio::Reader.new

subscribers = {
  initialize: -> {
    LSP::Interface::InitializeResult.new(
      capabilities: LSP::Interface::ServerCapabilities.new(
        text_document_sync: LSP::Interface::TextDocumentSyncOptions.new(
          change: LSP::Constant::TextDocumentSyncKind::FULL
        ),
        completion_provider: LSP::Interface::CompletionOptions.new(
          resolve_provider: true,
          trigger_characters: %w(.)
        ),
        definition_provider: true
      )
    )
  }
}

reader.read do |request|
  result = subscribers[request[:method].to_sym].call
  writer.write(id: request[:id], result: result)
  exit
end
```

You can use any IO object as transport layer:

```ruby
io = StringIO.new
writer = LSP::Transport::Io::Writer.new(io)
reader = LSP::Transport::Io::Reader.new(io)
```

## Versioning

language_server-protocol gem does NOT use semantic versioning.
This gem versions are structured as `x.y.z.t`.
`x.y.z` indicates the [Language server protocol](https://github.com/Microsoft/language-server-protocol/) version and `t` is a monotonically increasing number.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mtsmfm/language_server-protocol-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LanguageServer::Protocol project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mtsmfm/language_server-protocol-ruby/blob/main/CODE_OF_CONDUCT.md).
