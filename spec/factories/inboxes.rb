# frozen_string_literal: true

FactoryBot.define do
  factory :inbox do
    account
    association :channel, factory: :channel_widget
    name { "Inbox" }
  end
end
