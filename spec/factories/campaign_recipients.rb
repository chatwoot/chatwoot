# frozen_string_literal: true

FactoryBot.define do
  factory :campaign_recipient do
    status { :queued }
    phone_number { '+1234567890' }
    after(:build) do |recipient|
      recipient.account ||= create(:account)
      recipient.campaign ||= create(:campaign, account: recipient.account)
      recipient.inbox ||= recipient.campaign.inbox
      recipient.contact ||= create(:contact, :with_phone_number, account: recipient.account)
      recipient.phone_number ||= recipient.contact.phone_number
    end
  end
end
