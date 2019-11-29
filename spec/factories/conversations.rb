# frozen_string_literal: true

# == Schema Information
#
# Table name: conversations
#
#  id                    :integer          not null, primary key
#  additional_attributes :jsonb
#  agent_last_seen_at    :datetime
#  locked                :boolean          default(FALSE)
#  status                :integer          default("open"), not null
#  user_last_seen_at     :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  assignee_id           :integer
#  contact_id            :bigint
#  display_id            :integer          not null
#  inbox_id              :integer          not null
#
# Indexes
#
#  index_conversations_on_account_id                 (account_id)
#  index_conversations_on_account_id_and_display_id  (account_id,display_id) UNIQUE
#


FactoryBot.define do
  factory :conversation do
    status { 'open' }
    display_id { SecureRandom.uuid }
    user_last_seen_at { Time.current }
    agent_last_seen_at { Time.current }
    locked { false }

    factory :complete_conversation do
      after(:build) do |conversation|
        conversation.account ||= create(:account)
        conversation.inbox ||= create(
          :inbox,
          account: conversation.account,
          channel: create(:channel_widget, account: conversation.account)
        )
        conversation.contact ||= create(:contact, account: conversation.account)
        conversation.assignee ||= create(:user)
      end
    end
  end
end
