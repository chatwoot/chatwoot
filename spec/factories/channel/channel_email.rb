# frozen_string_literal: true

FactoryBot.define do
  factory :channel_email, class: 'Channel::Email' do
    sequence(:email) { |n| "care-#{n}@example.com" }
    sequence(:forward_to_email) { |n| "forward-#{n}@chatwoot.com" }
    account
    after(:create) do |channel_email|
      create(:inbox, channel: channel_email, account: channel_email.account)
    end

    trait :microsoft_email do
      imap_enabled { true }
      imap_address { 'outlook.office365.com' }
      imap_port { 993 }
      imap_login { 'email@example.com' }
      imap_password { '' }
      imap_enable_ssl { true }
      provider_config do
        {
          expires_on: Time.zone.now + 3600,
          access_token: SecureRandom.hex,
          refresh_token: SecureRandom.hex
        }
      end
      provider { 'microsoft' }
    end

    trait :imap_email do
      imap_enabled { true }
      imap_address { 'imap.gmail.com' }
      imap_port { 993 }
      imap_login { 'email@example.com' }
      imap_password { 'random-password' }
      imap_enable_ssl { true }
    end
  end
end
