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

  describe '#record_human_reply' do
    let!(:outcome) { tracker.record_eligibility(at: 2.minutes.ago) }

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

    it 'classifies an earlier resolution as assisted when events arrive out of order' do
      resolved_at = Time.current
      tracker.record_resolution(at: resolved_at, performed_by: assistant)
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: create(:user, account: account),
        message_type: :outgoing,
        created_at: 1.minute.ago
      )

      tracker.record_human_reply(message: message)

      expect(outcome.reload).to be_resolution_assisted
    end
  end

  describe '#record_resolution' do
    let(:eligible_at) { 5.minutes.ago }
    let!(:outcome) { tracker.record_eligibility(at: eligible_at) }

    it 'records an autonomous resolution performed by Captain' do
      resolved_at = Time.current

      tracker.record_resolution(at: resolved_at, performed_by: assistant)

      expect(outcome.reload).to have_attributes(
        captain_involved_at: resolved_at,
        resolution_type: 'autonomous',
        resolved_at: resolved_at,
        resolution_seconds: be_within(1).of(300)
      )
    end

    it 'records a resolution completed by a human as assisted' do
      resolved_at = Time.current
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

      tracker.record_resolution(at: resolved_at, performed_by: create(:user, account: account))

      expect(outcome.reload).to have_attributes(
        resolution_type: 'assisted',
        resolved_at: resolved_at
      )
    end

    it 'preserves the latest resolution when events arrive out of order' do
      latest_resolution_at = Time.current
      tracker.record_resolution(at: latest_resolution_at, performed_by: assistant)

      tracker.record_resolution(at: 1.minute.ago, performed_by: assistant)

      expect(outcome.reload.resolved_at).to eq(latest_resolution_at)
    end
  end

  describe '#record_reopen' do
    let!(:outcome) { tracker.record_eligibility(at: 5.minutes.ago) }

    before do
      tracker.record_resolution(at: 2.minutes.ago, performed_by: assistant)
    end

    it 'records reopenings after the latest resolution once' do
      reopened_at = Time.current

      tracker.record_reopen(at: reopened_at)
      tracker.record_reopen(at: reopened_at)

      expect(outcome.reload).to have_attributes(
        first_reopened_at: reopened_at,
        last_reopened_at: reopened_at,
        reopen_count: 1,
        durable_resolved_at: nil
      )
    end

    it 'ignores an opening that predates the latest resolution' do
      expect do
        tracker.record_reopen(at: 3.minutes.ago)
      end.not_to(change { outcome.reload.reopen_count })
    end
  end

  describe '#record_csat' do
    let!(:outcome) { tracker.record_eligibility(at: 5.minutes.ago) }

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
