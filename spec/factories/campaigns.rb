# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id                                 :bigint           not null, primary key
#  audience                           :jsonb
#  campaign_status                    :integer          default("active"), not null
#  campaign_type                      :integer          default("ongoing"), not null
#  description                        :text
#  enabled                            :boolean          default(TRUE)
#  message                            :text             not null
#  scheduled_at                       :datetime
#  template_params                    :jsonb
#  title                              :string           not null
#  trigger_only_during_business_hours :boolean          default(FALSE)
#  trigger_rules                      :jsonb
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  account_id                         :bigint           not null
#  display_id                         :integer          not null
#  inbox_id                           :bigint           not null
#  sender_id                          :integer
#
# Indexes
#
#  index_campaigns_on_account_id       (account_id)
#  index_campaigns_on_campaign_status  (campaign_status)
#  index_campaigns_on_campaign_type    (campaign_type)
#  index_campaigns_on_inbox_id         (inbox_id)
#  index_campaigns_on_scheduled_at     (scheduled_at)
#
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
