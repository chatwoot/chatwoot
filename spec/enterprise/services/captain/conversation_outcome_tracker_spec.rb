require 'rails_helper'

RSpec.describe Captain::ConversationOutcomeTracker do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }
  let(:tracker) { described_class.new(conversation: conversation, assistant: assistant) }

  def episodes
    ConversationOutcome.where(conversation_id: conversation.id).order(:started_at)
  end

  before do
    account.enable_features!('captain_integration_v2')
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
  end

  describe '#record_eligibility' do
    it 'creates the initial episode anchored to the demand time' do
      eligible_at = 2.minutes.ago.change(usec: 0)

      episode = tracker.record_eligibility(at: eligible_at)

      expect(episode.reload).to have_attributes(
        account: account,
        assistant: assistant,
        conversation: conversation,
        inbox: inbox,
        episode_trigger: 'initial',
        started_at: eligible_at,
        ended_at: nil
      )
    end

    it 'is idempotent' do
      tracker.record_eligibility(at: Time.current)

      expect do
        tracker.record_eligibility(at: Time.current)
      end.not_to change(ConversationOutcome, :count)
    end
  end

  describe '#record_reopen' do
    let(:initial_at) { 30.minutes.ago.change(usec: 0) }
    let!(:initial) { tracker.record_eligibility(at: initial_at) }

    it 'closes the open episode and opens a reopen episode' do
      boundary_at = 5.minutes.ago.change(usec: 0)

      tracker.record_reopen(at: boundary_at)

      expect(initial.reload.ended_at).to eq(boundary_at)
      expect(episodes.last).to have_attributes(
        episode_trigger: 'reopen',
        assistant: assistant,
        started_at: boundary_at,
        ended_at: nil
      )
    end

    it 'creates exactly one episode per boundary regardless of history' do
      tracker.record_reopen(at: 20.minutes.ago)
      tracker.record_reopen(at: 10.minutes.ago)

      expect do
        tracker.record_reopen(at: 1.minute.ago)
      end.to change(ConversationOutcome, :count).by(1)
    end

    it 'ignores boundaries for conversations without Captain history' do
      ConversationOutcome.delete_all

      expect do
        tracker.record_reopen(at: Time.current)
      end.not_to change(ConversationOutcome, :count)
    end

    it 'captures boundary failures without raising' do
      error = ActiveRecord::StatementInvalid.new('database unavailable')
      exception_tracker = instance_double(ChatwootExceptionTracker)
      allow(ConversationOutcome).to receive(:create!).and_raise(error)
      expect(ChatwootExceptionTracker).to receive(:new).with(error, account: account).and_return(exception_tracker)
      expect(exception_tracker).to receive(:capture_exception)

      expect do
        tracker.record_reopen(at: Time.current)
      end.not_to raise_error
    end
  end

  describe '#record_handoff' do
    let!(:initial) { tracker.record_eligibility(at: 30.minutes.ago) }

    it 'snapshots message facts and records the handoff reason' do
      first_reply = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: assistant, message_type: :outgoing, created_at: 20.minutes.ago.change(usec: 0)
      )
      last_reply = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: assistant, message_type: :outgoing, created_at: 10.minutes.ago.change(usec: 0)
      )
      handoff_at = 5.minutes.ago.change(usec: 0)
      tracker.record_handoff(at: handoff_at, reason_category: 'missing_knowledge')

      expect(initial.reload).to have_attributes(
        captain_reply_count: 2,
        first_captain_reply_at: first_reply.created_at,
        last_captain_reply_at: last_reply.created_at,
        handoff_at: handoff_at,
        handoff_reason_category: 'missing_knowledge'
      )
    end
  end

  describe '#record_resolution' do
    let!(:initial) { tracker.record_eligibility(at: 30.minutes.ago) }

    it 'snapshots the episode active at the resolution event time' do
      captain_reply = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: assistant, message_type: :outgoing, created_at: 20.minutes.ago.change(usec: 0)
      )
      resolved_at = 15.minutes.ago.change(usec: 0)
      tracker.record_reopen(at: 10.minutes.ago.change(usec: 0))

      tracker.record_resolution(at: resolved_at)

      expect(initial.reload).to have_attributes(
        captain_reply_count: 1,
        first_captain_reply_at: captain_reply.created_at,
        resolved_at: resolved_at
      )
      expect(episodes.last.resolved_at).to be_nil
    end

    it 'snapshots Captain and human replies through resolution' do
      captain_reply = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: assistant, message_type: :outgoing, created_at: 20.minutes.ago.change(usec: 0)
      )
      agent = create(:user, account: account)
      create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: agent, message_type: :outgoing, created_at: 15.minutes.ago,
        content_attributes: { automation_rule_id: 1 }
      )
      human_reply = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: agent, message_type: :outgoing, created_at: 10.minutes.ago.change(usec: 0)
      )
      resolved_at = 5.minutes.ago.change(usec: 0)

      tracker.record_resolution(at: resolved_at)

      expect(initial.reload).to have_attributes(
        captain_reply_count: 1,
        first_captain_reply_at: captain_reply.created_at,
        last_captain_reply_at: captain_reply.created_at,
        first_human_reply_at: human_reply.created_at,
        resolved_at: resolved_at
      )
    end
  end

  describe '#record_csat' do
    let!(:initial) { tracker.record_eligibility(at: 30.minutes.ago) }

    it 'attributes the response to the episode that issued its survey' do
      survey_message = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        content_type: :input_csat, created_at: 20.minutes.ago
      )
      tracker.record_reopen(at: 10.minutes.ago)
      response = create(
        :csat_survey_response,
        account: account, conversation: conversation, message: survey_message, rating: 4
      )

      tracker.record_csat(response: response)

      expect(initial.reload).to have_attributes(csat_rating: 4, csat_received_at: response.created_at)
      expect(episodes.last.csat_rating).to be_nil
    end
  end
end
