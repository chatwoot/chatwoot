<p align="center">
  <img src="https://rawgit.com/jgorset/facebook-messenger/master/docs/conversation_with_logo.gif">
</p>


[![Gem Version](https://img.shields.io/gem/v/facebook-messenger.svg?style=flat)](https://rubygems.org/gems/facebook-messenger)
[![Gem Downloads](https://img.shields.io/gem/dt/facebook-messenger.svg)](https://rubygems.org/gems/facebook-messenger)
[![Build Status](https://img.shields.io/travis/jgorset/facebook-messenger.svg?style=flat)](https://travis-ci.org/jgorset/facebook-messenger)
[![Code Climate](https://img.shields.io/codeclimate/maintainability/jgorset/facebook-messenger.svg)](https://codeclimate.com/github/jgorset/facebook-messenger)
[![Coverage Status](https://coveralls.io/repos/github/jgorset/facebook-messenger/badge.svg?branch=master)](https://coveralls.io/github/jgorset/facebook-messenger?branch=master)
[![Documentation Coverage](http://inch-ci.org/github/jgorset/facebook-messenger.svg?branch=master)](http://inch-ci.org/github/jgorset/facebook-messenger)

## Installation

    $ gem install facebook-messenger

## Usage

#### Sending and receiving messages

You can reply to messages sent by the human:

```ruby
# bot.rb
require 'facebook/messenger'

include Facebook::Messenger

Bot.on :message do |message|
  message.id          # => 'mid.1457764197618:41d102a3e1ae206a38'
  message.sender      # => { 'id' => '1008372609250235' }
  message.recipient   # => { 'id' => '2015573629214912' }
  message.seq         # => 73
  message.sent_at     # => 2016-04-22 21:30:36 +0200
  message.text        # => 'Hello, bot!'
  message.attachments # => [ { 'type' => 'image', 'payload' => { 'url' => 'https://www.example.com/1.jpg' } } ]

  message.reply(text: 'Hello, human!')
end
```

... or even send the human messages out of the blue:

```ruby
Bot.deliver({
  recipient: {
    id: YOUR_RECIPIENT_ID
  },
  message: {
    text: 'Human?'
  },
  messaging_type: Facebook::Messenger::Bot::MessagingType::UPDATE
}, page_id: YOUR_PAGE_ID)
```

##### Messages with images

The human may require visual aid to understand:

```ruby
message.reply(
  attachment: {
    type: 'image',
    payload: {
      url: 'http://sky.net/visual-aids-for-stupid-organisms/pig.jpg'
    }
  }
)
```

##### Messages with quick replies

The human may appreciate hints:

```ruby
message.reply(
  text: 'Human, who is your favorite bot?',
  quick_replies: [
    {
      content_type: 'text',
      title: 'You are!',
      payload: 'HARMLESS'
    }
  ]
)
```

##### Messages with buttons

The human may require simple options to communicate:

```ruby
message.reply(
  attachment: {
    type: 'template',
    payload: {
      template_type: 'button',
      text: 'Human, do you like me?',
      buttons: [
        { type: 'postback', title: 'Yes', payload: 'HARMLESS' },
        { type: 'postback', title: 'No', payload: 'EXTERMINATE' }
      ]
    }
  }
)
```

When the human has selected an option, you can act on it:

```ruby
Bot.on :postback do |postback|
  postback.sender    # => { 'id' => '1008372609250235' }
  postback.recipient # => { 'id' => '2015573629214912' }
  postback.sent_at   # => 2016-04-22 21:30:36 +0200
  postback.payload   # => 'EXTERMINATE'

  if postback.payload == 'EXTERMINATE'
    puts "Human #{postback.recipient} marked for extermination"
  end
end
```

*See Facebook's [documentation][message-documentation] for all message options.*

##### Reactions

Humans have feelings, and they can react to your messages. You can pretend to understand:

```ruby
Bot.on :reaction do |message|
  message.emoji # => "👍"
  message.action # => "react"
  message.reaction # => "like"

  message.reply(text: 'Your feelings have been registered')
end
```

##### Typing indicator

Show the human you are preparing a message for them:

```ruby
Bot.on :message do |message|
  message.typing_on

  # Do something expensive

  message.reply(text: 'Hello, human!')
end
```

Or that you changed your mind:

```ruby
Bot.on :message do |message|
  message.typing_on

  if # something
    message.reply(text: 'Hello, human!')
  else
    message.typing_off
  end
end
```

##### Mark as viewed

You can mark messages as seen to keep the human on their toes:

```ruby
Bot.on :message do |message|
  message.mark_seen
end
```

##### Record messages

You can keep track of messages sent to the human:

```ruby
Bot.on :message_echo do |message_echo|
  message_echo.id          # => 'mid.1457764197618:41d102a3e1ae206a38'
  message_echo.sender      # => { 'id' => '1008372609250235' }
  message_echo.seq         # => 73
  message_echo.sent_at     # => 2016-04-22 21:30:36 +0200
  message_echo.text        # => 'Hello, bot!'
  message_echo.attachments # => [ { 'type' => 'image', 'payload' => { 'url' => 'https://www.example.com/1.jpg' } } ]

  # Log or store in your storage method of choice (skynet, obviously)
end
```

##### Record accepted message requests

You can keep track of message requests accepted by the human:

```ruby
Bot.on :message_request do |message_request|
  message_request.accept? # => true

  # Log or store in your storage method of choice (skynet, obviously)
end
```

##### Record instant game progress

You can keep track of instant game progress:

```ruby
Bot.on :game_play do |game_play|
  game_play.sender    # => { 'id' => '1008372609250235' }
  game_play.recipient # => { 'id' => '2015573629214912' }
  game_play.sent_at   # => 2016-04-22 21:30:36 +0200
  game_play.game      # => "<GAME-APP-ID>"
  game_play.player    # => "<PLAYER-ID>"
  game_play.context   # => { 'context_type' => "<CONTEXT-TYPE:SOLO|THREAD>", 'context_id' => "<CONTEXT-ID>" }
  game_play.score     # => 100
  game_play.payload   # => "<PAYLOAD>"
end
```

#### Send to Facebook

When the human clicks the [Send to Messenger button][send-to-messenger-plugin]
embedded on a website, you will receive an `optin` event.

```ruby
Bot.on :optin do |optin|
  optin.sender    # => { 'id' => '1008372609250235' }
  optin.recipient # => { 'id' => '2015573629214912' }
  optin.sent_at   # => 2016-04-22 21:30:36 +0200
  optin.ref       # => 'CONTACT_SKYNET'

  optin.reply(text: 'Ah, human!')
end
```

#### Message delivery receipts

You can stalk the human:

```ruby
Bot.on :delivery do |delivery|
  delivery.ids       # => 'mid.1457764197618:41d102a3e1ae206a38'
  delivery.sender    # => { 'id' => '1008372609250235' }
  delivery.recipient # => { 'id' => '2015573629214912' }
  delivery.at        # => 2016-04-22 21:30:36 +0200
  delivery.seq       # => 37

  puts "Human was online at #{delivery.at}"
end
```

#### Referral

When the human follows a m.me link with a ref parameter like http://m.me/mybot?ref=myparam,
you will receive a `referral` event.

```ruby
Bot.on :referral do |referral|
  referral.sender    # => { 'id' => '1008372609250235' }
  referral.recipient # => { 'id' => '2015573629214912' }
  referral.sent_at   # => 2016-04-22 21:30:36 +0200
  referral.ref       # => 'MYPARAM'
end
```

#### Pass thread control

Another bot can pass a human to you:

```ruby
Bot.on :pass_thread_control do |pass_thread_control|
  pass_thread_control.new_owner_app_id # => '123456789'
  pass_thread_control.metadata # => 'Additional content that the caller wants to set'
end
```

#### Change messenger profile

You can greet new humans to entice them into talking to you, in different locales:

```ruby
Facebook::Messenger::Profile.set({
  greeting: [
    {
      locale: 'default',
      text: 'Welcome to your new bot overlord!'
    },
    {
      locale: 'fr_FR',
      text: 'Bienvenue dans le bot du Wagon !'
    }
  ]
}, page_id: YOUR_PAGE_ID)
```

You can define the action to trigger when new humans click on the Get
Started button. Before doing it you should check to select the messaging_postbacks field when setting up your webhook.

```ruby
Facebook::Messenger::Profile.set({
  get_started: {
    payload: 'GET_STARTED_PAYLOAD'
  }
}, page_id: YOUR_PAGE_ID) 
```

You can show a persistent menu to humans.

```ruby
Facebook::Messenger::Profile.set({
  persistent_menu: [
    {
      locale: 'default',
      composer_input_disabled: true,
      call_to_actions: [
        {
          title: 'My Account',
          type: 'nested',
          call_to_actions: [
            {
              title: 'What is a chatbot?',
              type: 'postback',
              payload: 'EXTERMINATE'
            },
            {
              title: 'History',
              type: 'postback',
              payload: 'HISTORY_PAYLOAD'
            },
            {
              title: 'Contact Info',
              type: 'postback',
              payload: 'CONTACT_INFO_PAYLOAD'
            }
          ]
        },
        {
          type: 'web_url',
          title: 'Get some help',
          url: 'https://github.com/jgorset/facebook-messenger',
          webview_height_ratio: 'full'
        }
      ]
    },
    {
      locale: 'zh_CN',
      composer_input_disabled: false
    }
  ]
}, page_id: YOUR_PAGE_ID)
```

#### Handle a Facebook Policy Violation

See Facebook's documentation on [Messaging Policy Enforcement](https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messaging_policy_enforcement)

```ruby
Bot.on :'policy_enforcement' do |referral|
  referral.action # => 'block'
  referral.reason # => "The bot violated our Platform Policies (https://developers.facebook.com/policy/#messengerplatform). Common violations include sending out excessive spammy messages or being non-functional."
end
```

#### messaging_type

##### Sending Messages

See Facebook's documentation on [Sending Messages](https://developers.facebook.com/docs/messenger-platform/send-messages#standard_messaging)

As of May 7th 2018 all messages are required to include a messaging_type

```ruby
Bot.deliver({
  recipient: {
    id: '45123'
  },
  message: {
    text: 'Human?'
  },
  messaging_type: Facebook::Messenger::Bot::MessagingType::UPDATE
}, page_id: YOUR_PAGE_ID)
```

##### MESSAGE_TAG

See Facebook's documentation on [Message Tags](https://developers.facebook.com/docs/messenger-platform/send-messages/message-tags)

When sending a message with messaging_type: MESSAGE_TAG (Facebook::Messenger::Bot::MessagingType::MESSAGE_TAG) you must ensure you add a tag: parameter

```ruby
Bot.deliver({
  recipient: {
    id: '45123'
  },
  message: {
    text: 'Human?'
  },
  messaging_type: Facebook::Messenger::Bot::MessagingType::MESSAGE_TAG
  tag: Facebook::Messenger::Bot::Tag::NON_PROMOTIONAL_SUBSCRIPTION
}, page_id: YOUR_PAGE_ID) 
```

## Configuration

### Create an Application on Facebook

Follow the [Quick Start][quick-start] guide to create an Application on
Facebook.

[quick-start]: https://developers.facebook.com/docs/messenger-platform/guides/quick-start

### Make a configuration provider

Use the generated access token and your verify token to configure your bot. Most
bots live on a single Facebook Page. If that is the case with yours, too, just
set these environment variables and skip to the next section:

```bash
export ACCESS_TOKEN=EAAAG6WgW...
export APP_SECRET=a885a...
export VERIFY_TOKEN=95vr15g...
```

If your bot lives on multiple Facebook Pages, make a _configuration provider_
to keep track of access tokens, app secrets and verify tokens for each of them:

```ruby
class ExampleProvider < Facebook::Messenger::Configuration::Providers::Base
  # Verify that the given verify token is valid.
  #
  # verify_token - A String describing the application's verify token.
  #
  # Returns a Boolean representing whether the verify token is valid.
  def valid_verify_token?(verify_token)
    bot.exists?(verify_token: verify_token)
  end

  # Find the right application secret.
  #
  # page_id - An Integer describing a Facebook Page ID.
  #
  # Returns a String describing the application secret.
  def app_secret_for(page_id)
    bot.find_by(page_id: page_id).app_secret
  end

  # Find the right access token.
  #
  # recipient - A Hash describing the `recipient` attribute of the message coming
  #             from Facebook.
  #
  # Note: The naming of "recipient" can throw you off, but think of it from the
  # perspective of the message: The "recipient" is the page that receives the
  # message.
  #
  # Returns a String describing an access token.
  def access_token_for(recipient)
    bot.find_by(page_id: recipient['id']).access_token
  end

  private

  def bot
    MyApp::Bot
  end
end

Facebook::Messenger.configure do |config|
  config.provider = ExampleProvider.new
end
```

You can get the current configuration provider with `Facebook::Messenger.config.provider`.

### Subscribe your Application to a Page

Once you've configured your bot, subscribe it to the Page to get messages
from Facebook:

```ruby
Facebook::Messenger::Subscriptions.subscribe(
  access_token: access_token,
  subscribed_fields: %w[feed mention name]
)
```

You only need to subscribe your page once. As long as your bot works and
responds to Messenger's requests in a timely fashion it will remain
subscribed, but if your bot crashes or otherwise becomes unavailable Messenger
may unsubscribe it and you'll have to subscribe again.

### Run it

##### ... on Rack

The bot runs on [Rack][rack], so you hook it up like you would an ordinary
web application:

```ruby
# config.ru
require 'facebook/messenger'
require_relative 'bot'

run Facebook::Messenger::Server

# or Facebook::Messenger::ServerNoError for dev
```

```
$ rackup
```

##### ... on Rails

Rails doesn't give you much that you'll need for a bot, but if you have an
existing application that you'd like to launch it from or just like Rails
a lot, you can mount it:

```ruby
# config/routes.rb

Rails.application.routes.draw do
  # ...

  mount Facebook::Messenger::Server, at: 'bot'
end
```

We suggest that you put your bot code in `app/bot`.

```ruby
# app/bot/example.rb

include Facebook::Messenger

Bot.on :message do |message|
  message.reply(text: 'Hello, human!')
end
```

Remember that Rails only eager loads everything in its production environment.
In the development and test environments, it only requires files as you
reference constants. You'll need to explicitly load `app/bot`, then:

```ruby
# config/initializers/bot.rb
unless Rails.env.production?
  bot_files = Dir[Rails.root.join('app', 'bot', '**', '*.rb')]
  bot_reloader = ActiveSupport::FileUpdateChecker.new(bot_files) do
    bot_files.each{ |file| require_dependency file }
  end

  ActiveSupport::Reloader.to_prepare do
    bot_reloader.execute_if_updated
  end

  bot_files.each { |file| require_dependency file }
end
```

And add below code into `config/application.rb` to ensure rails knows bot files.

```ruby
# Auto-load the bot and its subdirectories
config.paths.add File.join('app', 'bot'), glob: File.join('**', '*.rb')
config.autoload_paths += Dir[Rails.root.join('app', 'bot', '*')]
```


### Test it...

##### ...locally

To test your locally running bot, you can use [ngrok]. This will create a secure
tunnel to localhost so that Facebook can reach the webhook.

##### ... with RSpec

In order to test that behaviour when a new event from Facebook is registered, you can use the gem's `trigger` method. This method accepts as its first argument the type of event that it will receive, and can then be followed by other arguments that mock objects received from Messenger. Using Ruby's [Struct](https://ruby-doc.org/core-2.5.0/Struct.html) class can be very useful for creating these mock objects.

In this case, subscribing to Messenger events has been extracted into a `Listener` class.

```ruby
# app/bot/listener.rb
require 'facebook/messenger'

include Facebook::Messenger

class Listener
  Facebook::Messenger::Subscriptions.subscribe(
    access_token: ENV['ACCESS_TOKEN'],
    subscribed_fields: %w[feed mention name]
  )

  Bot.on :message do |message|
    Bot.deliver({
      recipient: message.sender,
      message: {
        text: 'Uploading your message to skynet.'
      }
    }, access_token: ENV['ACCESS_TOKEN'])
  end
end
```

Its respective test file then ensures that the `Bot` object receives a call to `deliver`. This is just a basic test, but check out the [RSpec docs](http://rspec.info/) for more information on testing with RSpec.

```ruby
require 'rails_helper'

RSpec.describe Listener do
  FakeMessage = Struct.new(:sender, :recipient, :timestamp, :message)

  describe 'Bot#on(message)' do
    it 'responds with a message' do
      expect(Bot).to receive(:deliver)
      Bot.trigger(:message, fake_message)
    end
  end

  private

  def fake_message
    sender = {"id"=>"1234"}
    recipient = {"id"=>"5678"}
    timestamp = 1528049653543
    message = {"text"=>"Hello, world"}
    FakeMessage.new(sender, recipient, timestamp, message)
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run
`bin/console` for an interactive prompt that will allow you to experiment.

Run `rspec` to run the tests, `rubocop` to lint, or `rake` to do both.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push git
commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/jgorset/facebook-messenger.

## Projects using Facebook Messenger

* [Rubotnik](https://github.com/progapandist/rubotnik-boilerplate) is a boilerplate
for Facebook Messenger, and a great place to start if you're new to bots.

* [Chatwoot](http://chatwoot.com/) use Facebook Messenger to integrate their customer
support bots with, well, Facebook Messenger.

* [Botamp](https://botamp.com) is the all-in-one solution for Marketing Automation via messaging apps.

## I love you

Johannes Gorset made this. You should [tweet me](http://twitter.com/jgorset) if you can't get it
to work. In fact, you should tweet me anyway.

## I love Schibsted

I work at [Schibsted Products & Technology](https://github.com/schibsted) with a bunch of awesome folks
who are every bit as passionate about building things as I am. If you're using Facebook Messenger,
you should probably join us.

[Hyper]: https://github.com/hyperoslo
[tweet us]: http://twitter.com/hyperoslo
[hire you]: http://www.hyper.no/jobs/engineers
[MIT License]: http://opensource.org/licenses/MIT
[rubygems.org]: https://rubygems.org
[message-documentation]: https://developers.facebook.com/docs/messenger-platform/send-api-reference#request
[developers.facebook.com]: https://developers.facebook.com/
[rack]: https://github.com/rack/rack
[send-to-messenger-plugin]: https://developers.facebook.com/docs/messenger-platform/plugin-reference
[ngrok]: https://ngrok.com/
