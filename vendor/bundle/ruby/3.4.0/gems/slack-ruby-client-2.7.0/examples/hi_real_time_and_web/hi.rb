# frozen_string_literal: true
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts(
    "Successfully connected, welcome '#{client.self.name}' " \
    "to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
  )
end

client.on :message do |data|
  puts data
  case data.text
  when 'bot hi'
    client.web_client.chat_postMessage channel: data.channel, text: "Hi <@#{data.user}>!"
  when /^bot/
    client.web_client.chat_postMessage channel: data.channel, text: "Sorry <@#{data.user}>, what?"
  end
end

client.start!
