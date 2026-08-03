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
      outcome = tracker.record_eligibility

      expect(outcome).to have_attributes(
        account: account,
        assistant: assistant,
        conversation: conversation,
        inbox: inbox
      )
    end

    it 'is idempotent' do
      tracker.record_eligibility

      expect do
        tracker.record_eligibility
      end.not_to change(ConversationOutcome, :count)
    end

    it 'does not create outcomes for Captain V1' do
      account.disable_features!('captain_integration_v2')

      expect do
        tracker.record_eligibility
      end.not_to change(ConversationOutcome, :count)
    end
  end

  describe '#record_captain_reply' do
    let!(:outcome) { tracker.record_eligibility }

    it 'records the reply timestamps and the public reply count' do
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
        first_captain_reply_at: message.created_at,
        last_captain_reply_at: message.created_at,
        captain_reply_count: 1
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

      expect(outcome.reload.first_captain_reply_at).to be_nil
    end
  end

  describe '#record_handoff' do
    let!(:outcome) { tracker.record_eligibility }

    it 'records the handoff details' do
      handed_off_at = Time.current

      tracker.record_handoff(at: handed_off_at, reason_category: 'unsupported_request')

      expect(outcome.reload).to have_attributes(
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

  describe '#record_human_reply' do
    let!(:outcome) { tracker.record_eligibility }

    it 'records the first public human reply' do
      agent = create(:user, account: account)
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: agent,
        message_type: :outgoing,
        created_at: 1.minute.ago
      )

      tracker.record_human_reply(message: message)

      expect(outcome.reload.first_human_reply_at).to eq(message.created_at)
    end

    it 'ignores private notes from agents' do
      agent = create(:user, account: account)
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: agent,
        message_type: :outgoing,
        private: true
      )

      tracker.record_human_reply(message: message)

      expect(outcome.reload.first_human_reply_at).to be_nil
    end
  end

  describe '#record_resolution' do
    let!(:outcome) { tracker.record_eligibility }

    it 'records the resolution time' do
      resolved_at = Time.current

      tracker.record_resolution(at: resolved_at)

      expect(outcome.reload.resolved_at).to eq(resolved_at)
    end

    it 'preserves the latest resolution when events arrive out of order' do
      latest_resolution_at = Time.current
      tracker.record_resolution(at: latest_resolution_at)

      tracker.record_resolution(at: 1.minute.ago)

      expect(outcome.reload.resolved_at).to eq(latest_resolution_at)
    end
  end

  describe '#record_reopen' do
    let!(:outcome) { tracker.record_eligibility }

    before do
      tracker.record_resolution(at: 2.minutes.ago)
    end

    it 'records reopenings after the latest resolution once' do
      reopened_at = Time.current

      tracker.record_reopen(at: reopened_at)
      tracker.record_reopen(at: reopened_at)

      expect(outcome.reload).to have_attributes(
        last_reopened_at: reopened_at,
        reopen_count: 1
      )
    end

    it 'ignores an opening that predates the latest resolution' do
      expect do
        tracker.record_reopen(at: 3.minutes.ago)
      end.not_to(change { outcome.reload.reopen_count })
    end

    it 'ignores openings on an unresolved outcome' do
      outcome.reload.update!(resolved_at: nil)

      expect do
        tracker.record_reopen(at: Time.current)
      end.not_to(change { outcome.reload.reopen_count })
    end
  end

  describe '#record_csat' do
    let!(:outcome) { tracker.record_eligibility }

    it 'records the latest CSAT response' do
      message = create(:message, account: account, inbox: inbox, conversation: conversation)
      response = create(
        :csat_survey_response,
        account: account,
        conversation: conversation,
        contact: conversation.contact,
        message: message,
        rating: 5
      )

      tracker.record_csat(response: response)

      expect(outcome.reload).to have_attributes(
        csat_rating: 5,
        csat_received_at: response.created_at
      )
    end
  end
end
