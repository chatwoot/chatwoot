# frozen_string_literal: true

FactoryBot.define do
  factory :channel_line, class: 'Channel::Line' do
    line_channel_id { SecureRandom.uuid }
    line_channel_secret { SecureRandom.uuid }
    line_channel_token { SecureRandom.uuid }
    inbox
    account
  end
end
