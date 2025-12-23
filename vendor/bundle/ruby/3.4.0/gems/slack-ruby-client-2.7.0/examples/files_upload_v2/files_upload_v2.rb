# frozen_string_literal: true
require 'slack-ruby-client'
require 'securerandom'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

client = Slack::Web::Client.new

auth = client.auth_test
puts "Connected to team #{auth.team} (#{auth.team_id}) as #{auth.user}."

puts client.files_upload_v2(
  filename: 'files_upload_v2.txt',
  content: SecureRandom.hex
).files.first.permalink_public

puts client.files_upload_v2(
  filename: 'files_upload_v2_to_general_channel.txt',
  content: SecureRandom.hex,
  channel: '#general'
).files.first.permalink_public

puts client.files_upload_v2(
  filename: 'files_upload_v2_to_general_and_random_channels.txt',
  content: SecureRandom.hex,
  channels: ['#general', '#random']
).files.first.permalink_public

channel_id = client.conversations_id(channel: '#general')['channel']['id']
puts client.files_upload_v2(
  filename: 'files_upload_v2_to_general_by_id.txt',
  content: SecureRandom.hex,
  channel_id: channel_id
).files.first.permalink_public

client.files_upload_v2(
  files: [
    { filename: 'files_upload_v2_to_general_first_file.txt', content: SecureRandom.hex },
    { filename: 'files_upload_v2_to_general_second_file.txt', content: SecureRandom.hex }
  ],
  channels: ['#general']
).files.each { |file| puts file.permalink_public }
