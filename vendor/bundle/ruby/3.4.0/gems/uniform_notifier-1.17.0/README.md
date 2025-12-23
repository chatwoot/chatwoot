# UniformNotifier

[![CI](https://github.com/flyerhzm/uniform_notifier/actions/workflows/ci.yml/badge.svg)](https://github.com/flyerhzm/uniform_notifier/actions/workflows/ci.yml)
[![AwesomeCode Status for flyerhzm/uniform_notifier](https://awesomecode.io/projects/3e29a7de-0b37-4ecf-b06d-410ebf815174/status)](https://awesomecode.io/repos/flyerhzm/uniform_notifier)

uniform_notifier is extracted from [bullet][0], it gives you the ability to send notification through rails logger, customized logger, javascript alert, javascript console, xmpp, airbrake, honeybadger and AppSignal.

## Install

### install directly

    gem install uniform_notifier

if you want to notify by xmpp, you should install xmpp4r first

    gem install xmpp4r

if you want to notify by airbrake, you should install airbrake first

    gem install airbrake

if you want to notify by Honeybadger, you should install honeybadger first

    gem install honeybadger

if you want to notify by rollbar, you should install rollbar first

    gem install rollbar

if you want to notify by bugsnag, you should install bugsnag first

    gem install bugsnag

if you want to notify by AppSignal, you should install AppSignal first

    gem install appsignal

if you want to notify by slack, you should install slack-notifier first

    gem install slack-notifier

if you want to notify by terminal-notifier, you must install it first

    gem install terminal-notifier

### add it into Gemfile (Bundler)

    gem "uniform_notifier"

  you should add xmpp4r, airbrake, bugsnag, honeybadger, slack-notifier, terminal-notifier gem if you want.

## Usage

There are two types of notifications,
one is <code>inline_notify</code>, for javascript alert and javascript console notifiers, which returns a string and will be combined,
the other is <code>out_of_channel_notify</code>, for rails logger, customized logger, xmpp, which doesn't return anything, just send the message to the notifiers.

By default, all notifiers are disabled, you should enable them first.

```ruby
# javascript alert
UniformNotifier.alert = true
# javascript alert with options
# the attributes key adds custom attributes to the script tag appended to the body
UniformNotifier.alert = { :attributes => { :nonce => 'mySecret-nonce', 'data-key' => 'value' } }

# javascript console (Safari/Webkit browsers or Firefox w/Firebug installed)
UniformNotifier.console = true
# javascript console with options
# the attributes key adds custom attributes to the script tag appended to the body
UniformNotifier.console = { :attributes => { :nonce => 'mySecret-nonce', 'data-key' => 'value' } }

# rails logger
UniformNotifier.rails_logger = true

# airbrake
UniformNotifier.airbrake = true
# airbrake with options
UniformNotifier.airbrake = { :error_class => Exception }

# AppSignal
UniformNotifier.appsignal = true
# AppSignal with options
UniformNotifier.appsignal = { :namespace => "Background", :tags => { :hostname => "frontend1" } }

# Honeybadger
#
# Reporting live data from development is disabled by default. Ensure
# that the `report_data` option is enabled via configuration.
UniformNotifier.honeybadger = true
# Honeybadger with options
UniformNotifier.honeybadger = { :error_class => 'Exception' }

# rollbar
UniformNotifier.rollbar = true
# rollbar with options (level can be 'debug', 'info', 'warning', 'error' or 'critical')
UniformNotifier.rollbar = { :level => 'warning' }

# bugsnag
UniformNotifier.bugsnag = true
# bugsnag with options
UniformNotifier.bugsnag = { :api_key => 'something' }

# slack
UniformNotifier.slack = true
# slack with options
UniformNotifier.slack = { :webhook_url => 'http://some.slack.url', :channel => '#default', :username => 'notifier' }

# customized logger
logger = File.open('notify.log', 'a+')
logger.sync = true
UniformNotifier.customized_logger = logger

# xmpp
UniformNotifier.xmpp = { :account => 'sender_account@jabber.org',
                         :password => 'password_for_jabber',
                         :receiver => 'recipient_account@jabber.org',
                         :show_online_status => true }

# terminal-notifier
UniformNotifier.terminal_notifier = true

# raise an error
UniformNotifier.raise = true # raise a generic exception

class MyExceptionClass < Exception; end
UniformNotifier.raise = MyExceptionClass # raise a custom exception type

UniformNotifier.raise = false # don't raise errors
```

After that, you can enjoy the notifiers, that's cool!

```ruby
# the notify message will be notified to rails logger, customized logger or xmpp.
UniformNotifier.active_notifiers.each do |notifier|
  notifier.out_of_channel_notify("customize message")
end

# the notify message will be wrapped by <script type="text/javascript">...</script>,
# you should append the javascript_str at the bottom of http response body.
# for more information, please check https://github.com/flyerhzm/bullet/blob/master/lib/bullet/rack.rb
responses = []
UniformNotifier.active_notifiers.each do |notifier|
  responses << notifier.inline_notify("customize message")
end
javascript_str = responses.join("\n")
```

## XMPP/Jabber Support

To get XMPP support up-and-running, follow the steps below:

* Install the xmpp4r gem: <code>gem install xmpp4r</code>
* Make both the sender and the recipient account add each other as contacts.
  This will require you to manually log into both accounts, add each other
  as contact and confirm each others contact request.
* Boot up your application. UniformNotifier will automatically send an XMPP notification when XMPP is turned on.


[0]: https://github.com/flyerhzm/bullet
