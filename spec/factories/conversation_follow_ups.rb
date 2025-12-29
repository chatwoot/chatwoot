# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_follow_up do
    current_step { 0 }
    next_action_at { 2.hours.from_now }
    status { 'active' }
    metadata { {} }
    processing_started_at { nil }

    after(:build) do |follow_up|
      unless follow_up.conversation
        account = create(:account)
        whatsapp_channel = create(:channel_whatsapp, account: account)
        whatsapp_inbox = create(:inbox, channel: whatsapp_channel, account: account)
        follow_up.conversation = create(:conversation, account: account, inbox: whatsapp_inbox)
      end

      follow_up.lead_follow_up_sequence ||= create(
        :lead_follow_up_sequence,
        account: follow_up.conversation.account,
        inbox: follow_up.conversation.inbox
      )
    end

    trait :completed do
      status { 'completed' }
      metadata do
        {
          'completed_at' => Time.current.iso8601,
          'completion_reason' => 'Contact replied'
        }
      end
    end

    trait :cancelled do
      status { 'cancelled' }
      metadata do
        {
          'cancelled_at' => Time.current.iso8601,
          'cancellation_reason' => 'Sequence deactivated'
        }
      end
    end

    trait :failed do
      status { 'failed' }
      metadata do
        {
          'failed_at' => Time.current.iso8601,
          'failure_reason' => 'Template not found'
        }
      end
    end

    trait :processing do
      processing_started_at { Time.current }
    end
  end
end
