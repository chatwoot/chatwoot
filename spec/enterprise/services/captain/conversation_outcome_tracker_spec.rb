require 'rails_helper'

RSpec.describe Captain::ConversationOutcomeTracker do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }
  let(:tracker) { described_class.new(conversation: conversation, assistant: assistant) }

  before do
    account.enable_features!('captain_integration_v2')
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
  end

  describe '#record_eligibility' do
    it 'creates the V2 conversation outcome' do
      eligible_at = 2.minutes.ago

      outcome = tracker.record_eligibility(at: eligible_at)

      expect(outcome).to have_attributes(
        account: account,
        assistant: assistant,
        conversation: conversation,
        inbox: inbox,
        eligible_at: eligible_at
      )
    end

    it 'is idempotent and preserves the earliest eligibility time' do
      first_eligible_at = 3.minutes.ago
      tracker.record_eligibility(at: 1.minute.ago)

      expect do
        tracker.record_eligibility(at: first_eligible_at)
      end.not_to change(Captain::ConversationOutcome, :count)

      expect(Captain::ConversationOutcome.last.eligible_at).to be_within(1.second).of(first_eligible_at)
    end

    it 'does not create outcomes for Captain V1' do
      account.disable_features!('captain_integration_v2')

      expect do
        tracker.record_eligibility(at: Time.current)
      end.not_to change(Captain::ConversationOutcome, :count)
    end
  end

  describe '#record_captain_reply' do
    let!(:outcome) { tracker.record_eligibility(at: 2.minutes.ago) }

    it 'records involvement, response time, and the public reply count' do
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: assistant,
        message_type: :outgoing,
        created_at: 1.minute.ago
      )

      tracker.record_captain_reply(message: message)

      expect(outcome.reload).to have_attributes(
        captain_involved_at: message.created_at,
        first_captain_reply_at: message.created_at,
        last_captain_reply_at: message.created_at,
        captain_reply_count: 1,
        first_response_seconds: 60
      )
    end

    it 'is idempotent and keeps the first and last reply timestamps' do
      first_message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: assistant,
        message_type: :outgoing,
        created_at: 90.seconds.ago
      )
      second_message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: assistant,
        message_type: :outgoing,
        created_at: 30.seconds.ago
      )

      tracker.record_captain_reply(message: second_message)
      tracker.record_captain_reply(message: first_message)
      tracker.record_captain_reply(message: second_message)

      expect(outcome.reload).to have_attributes(
        first_captain_reply_at: first_message.created_at,
        last_captain_reply_at: second_message.created_at,
        captain_reply_count: 2
      )
    end

    it 'ignores private Captain messages' do
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: assistant,
        message_type: :outgoing,
        private: true
      )

      tracker.record_captain_reply(message: message)

      expect(outcome.reload.captain_involved_at).to be_nil
    end
  end

  describe '#record_handoff' do
    let!(:outcome) { tracker.record_eligibility(at: 2.minutes.ago) }

    it 'records Captain involvement and the handoff details' do
      handed_off_at = Time.current

      tracker.record_handoff(
        at: handed_off_at,
        reason_category: 'unsupported_request'
      )

      expect(outcome.reload).to have_attributes(
        captain_involved_at: handed_off_at,
        handoff_at: handed_off_at,
        handoff_reason_category: 'unsupported_request'
      )
    end

    it 'preserves the first handoff and its reason category' do
      first_handoff_at = 1.minute.ago
      tracker.record_handoff(at: first_handoff_at, reason_category: 'missing_knowledge')

      tracker.record_handoff(at: Time.current, reason_category: 'unsupported_request')

      expect(outcome.reload).to have_attributes(
        handoff_at: first_handoff_at,
        handoff_reason_category: 'missing_knowledge'
      )
    end
  end
end
