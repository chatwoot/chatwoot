FactoryBot.define do
  factory :channel_group do
    sequence(:name) { |n| "Channel group #{n}" }
    account
  end
end
