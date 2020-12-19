# frozen_string_literal: true

FactoryBot.define do
  factory :channel_email, class: 'Channel::Email' do
    sequence(:email) { |n| "care-#{n}@example.com" }
    sequence(:forward_to_address) { |n| "forward-#{n}@chatwoot.com" }
    account
    after(:create) do |channel_email|
      create(:inbox, channel: channel_email, account: channel_email.account)
    end
  end
end
