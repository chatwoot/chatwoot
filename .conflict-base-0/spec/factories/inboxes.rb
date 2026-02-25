# frozen_string_literal: true

FactoryBot.define do
  factory :inbox do
    account
    channel { FactoryBot.build(:channel_widget, account: account) }
    name { 'Inbox' }

    after(:create) do |inbox|
      inbox.channel.save!
    end

    trait :with_email do
      channel { FactoryBot.build(:channel_email, account: account) }
      name { 'Email Inbox' }
    end
  end
end
