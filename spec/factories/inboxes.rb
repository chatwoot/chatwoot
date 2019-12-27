# frozen_string_literal: true

FactoryBot.define do
  factory :inbox do
    account
    name { 'Inbox' }
    channel { FactoryBot.build(:channel_widget, account: account) }
  end
end
