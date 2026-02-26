# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                            :integer          not null, primary key
#  allow_messages_after_resolved :boolean          default(TRUE)
#  auto_assignment_config        :jsonb
#  business_name                 :string
#  channel_type                  :string
#  csat_config                   :jsonb            not null
#  csat_survey_enabled           :boolean          default(FALSE)
#  email_address                 :string
#  enable_auto_assignment        :boolean          default(TRUE)
#  enable_email_collect          :boolean          default(TRUE)
#  greeting_enabled              :boolean          default(FALSE)
#  greeting_message              :string
#  lock_to_single_conversation   :boolean          default(FALSE), not null
#  name                          :string           not null
#  out_of_office_message         :string
#  sender_name_type              :integer          default("friendly"), not null
#  timezone                      :string           default("UTC")
#  working_hours_enabled         :boolean          default(FALSE)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  account_id                    :integer          not null
#  channel_id                    :integer          not null
#  portal_id                     :bigint
#
# Indexes
#
#  index_inboxes_on_account_id                   (account_id)
#  index_inboxes_on_channel_id_and_channel_type  (channel_id,channel_type)
#  index_inboxes_on_portal_id                    (portal_id)
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => portals.id)
#
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
