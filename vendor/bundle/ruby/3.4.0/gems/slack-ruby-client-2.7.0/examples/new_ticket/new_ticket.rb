# frozen_string_literal: true
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

client = Slack::Web::Client.new

client.auth_test

client.chat_postMessage(
  channel: '#general',
  as_user: true,
  attachments: [
    {
      fallback: "Ticket #1943: Can't reset my password - https://groove.hq/path/to/ticket/1943",
      pretext: 'New ticket from Andrea Lee',
      title: "Ticket #1943: Can't reset my password",
      title_link: 'https://groove.hq/path/to/ticket/1943',
      text: 'Help! I tried to reset my password but nothing happened!',
      color: '#7CD197'
    }
  ]
)
