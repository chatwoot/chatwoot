# Incoming Email via Amazon SES

Chatwoot supports processing incoming email with Amazon Simple Email Service (SES) using the [`aws-actionmailbox-ses`](https://docs.aws.amazon.com/sdk-for-ruby/aws-actionmailbox-ses/api/file.README.html) ingress.

## Installation

Add the required gems to your `Gemfile`:

```ruby
gem 'aws-sdk-rails', '~> 4'
gem 'aws-actionmailbox-ses', '~> 0'
```

Then run `bundle install`.

## Configuration

Set the ingress service and configure the SNS topic and S3 region:

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :ses
config.action_mailbox.ses.subscribed_topic = 'arn:aws:sns:us-west-2:012345678910:example-topic-1'
config.action_mailbox.ses.s3_client_options = { region: 'us-east-1' }
```

SNS subscriptions are auto-confirmed and messages from unlisted topics are ignored. Finally, set `RAILS_INBOUND_EMAIL_SERVICE=ses` in your environment.
