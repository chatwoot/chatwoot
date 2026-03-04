# frozen_string_literal: true

FactoryBot.define do
  factory :group_contact do
    account
    conversation { association :conversation, group: true, account: account }
    contact { association :contact, account: account }
  end
end
