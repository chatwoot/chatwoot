# frozen_string_literal: true

FactoryBot.define do
  factory :campaign do
    sequence(:title) { |n| "Campaign #{n}" }
    sequence(:message) { |n| "Campaign message #{n}" }
    after(:build) do |campaign|
      campaign.account ||= create(:account)
      campaign.inbox ||= create(
        :inbox,
        account: campaign.account,
        channel: create(:channel_widget, account: campaign.account)
      )
    end
  end
end
