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

    trait :whatsapp do
      after(:build) do |campaign|
        campaign.inbox = create(
          :inbox,
          account: campaign.account,
          channel: create(:channel_whatsapp, account: campaign.account)
        )
        campaign.template_params = {
          'name' => 'ticket_status_updated',
          'namespace' => '23423423_2342423_324234234_2343224',
          'category' => 'UTILITY',
          'language' => 'en',
          'processed_params' => { 'name' => 'John', 'ticket_id' => '2332' }
        }
      end
    end
  end
end
