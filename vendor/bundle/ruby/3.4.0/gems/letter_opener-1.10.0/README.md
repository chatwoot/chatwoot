# Letter Opener [![Ruby](https://github.com/ryanb/letter_opener/actions/workflows/ruby.yml/badge.svg)](https://github.com/ryanb/letter_opener/actions/workflows/ruby.yml)

Preview email in the default browser instead of sending it. This means you do not need to set up email delivery in your development environment, and you no longer need to worry about accidentally sending a test email to someone else's address.

## Rails Setup

First add the gem to your development environment and run the `bundle` command to install it.

```rb
gem "letter_opener", group: :development
```

Then set the delivery method in `config/environments/development.rb`

```rb
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
```

Now any email will pop up in your browser instead of being sent. The messages are stored in `tmp/letter_opener`.
If you want to change application that will be used to open your emails you should override `LAUNCHY_APPLICATION` environment variable or set `Launchy.application` in the initializer.

### Configuration

```rb
LetterOpener.configure do |config|
  # To overrider the location for message storage.
  # Default value is `tmp/letter_opener`
  config.location = Rails.root.join('tmp', 'my_mails')

  # To render only the message body, without any metadata or extra containers or styling.
  # Default value is `:default` that renders styled message with showing useful metadata.
  config.message_template = :light

  # To change default file URI scheme you can provide `file_uri_scheme` config.
  # It might be useful when you use WSL (Windows Subsystem for Linux) and default
  # scheme doesn't work for you.
  # Default value is blank
  config.file_uri_scheme = 'file://///wsl$/Ubuntu-18.04'
end
```

## Non Rails Setup

If you aren't using Rails, this can be easily set up with the Mail gem. Just set the delivery method when configuring Mail and specify a location.

```rb
require "letter_opener"
Mail.defaults do
  delivery_method LetterOpener::DeliveryMethod, location: File.expand_path('../tmp/letter_opener', __FILE__)
end
```

The method is similar if you're using the Pony gem:

```rb
require "letter_opener"
Pony.options = {
  via: LetterOpener::DeliveryMethod,
  via_options: {location: File.expand_path('../tmp/letter_opener', __FILE__)}
}
```

Alternatively, if you are using ActionMailer directly (without Rails) you will need to add the delivery method.

```rb
require "letter_opener"
ActionMailer::Base.add_delivery_method :letter_opener, LetterOpener::DeliveryMethod, :location => File.expand_path('../tmp/letter_opener', __FILE__)
ActionMailer::Base.delivery_method = :letter_opener
```

## Remote Alternatives

Letter Opener uses [Launchy](https://github.com/copiousfreetime/launchy) to open sent mail in the browser. This assumes the Ruby process is running on the local development machine. If you are using a separate staging server or VM this will not work. In that case consider using [Mailtrap](http://mailtrap.io/) or [MailCatcher](http://mailcatcher.me/).

If you are running your application within a Docker Container or VM and do not have a browser available to open emails received by Letter Opener, you may see the following error:

```
WARN: Launchy::CommandNotFoundError: Unable to find a browser command. If this is unexpected, Please rerun with environment variable LAUNCHY_DEBUG=true or the '-d' commandline option and file a bug at https://github.com/copiousfreetime/launchy/issues/new
```

To resolve this, simply set the following ENV variables:

```
LAUNCHY_DRY_RUN=true
BROWSER=/dev/null
```

In order to keep this project simple, I don't have plans to turn it into a Rails engine with an interface for browsing the sent mail but there is a [gem you can use for that](https://github.com/fgrehm/letter_opener_web).


## Development & Feedback

Questions or problems? Please use the [issue tracker](https://github.com/ryanb/letter_opener/issues). If you would like to contribute to this project, fork this repository and run `bundle` and `rake` to run the tests. Pull requests appreciated.

Special thanks to the [mail_view](https://github.com/37signals/mail_view/) gem for inspiring this project and for their mail template. Also thanks to [Vasiliy Ermolovich](https://github.com/nashby) for helping manage this project.
