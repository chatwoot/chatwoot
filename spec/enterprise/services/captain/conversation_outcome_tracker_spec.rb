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
      eligible_at = 2.minutes.ago

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

    it 'lowers the initial anchor when an earlier eligible message arrives late' do
      episode = tracker.record_eligibility(at: Time.current)

      earlier_eligible_at = 2.minutes.ago
      tracker.record_eligibility(at: earlier_eligible_at)

      expect(episode.reload.started_at).to eq(earlier_eligible_at)
    end

    it 'inserts a missing initial episode before an existing reopen boundary' do
      boundary_at = 1.minute.ago
      reopen_episode = create(
        :conversation_outcome,
        account: account, assistant: assistant, conversation: conversation, inbox: inbox,
        episode_trigger: 'reopen', started_at: boundary_at
      )

      eligible_at = 10.minutes.ago
      tracker.record_eligibility(at: eligible_at)

      initial = episodes.first
      expect(initial).to have_attributes(episode_trigger: 'initial', started_at: eligible_at, ended_at: boundary_at)
      expect(reopen_episode.reload.started_at).to eq(boundary_at)
    end

    it 'does not create episodes for Captain V1' do
      account.disable_features!('captain_integration_v2')

      expect do
        tracker.record_eligibility(at: Time.current)
      end.not_to change(ConversationOutcome, :count)
    end
  end

  describe '#record_reopen' do
    let(:initial_at) { 30.minutes.ago }
    let!(:initial) { tracker.record_eligibility(at: initial_at) }

    it 'closes the open episode and opens a reopen episode' do
      boundary_at = 5.minutes.ago

      tracker.record_reopen(at: boundary_at)

      expect(initial.reload.ended_at).to eq(boundary_at)
      expect(episodes.last).to have_attributes(
        episode_trigger: 'reopen',
        assistant: assistant,
        started_at: boundary_at,
        ended_at: nil
      )
    end

    it 'ignores a redelivered boundary' do
      boundary_at = 5.minutes.ago
      tracker.record_reopen(at: boundary_at)

      expect do
        tracker.record_reopen(at: boundary_at)
      end.not_to change(ConversationOutcome, :count)
    end

    it 'slots boundaries delivered in reverse order into chronological windows' do
      later_at = 5.minutes.ago
      earlier_at = 15.minutes.ago

      tracker.record_reopen(at: later_at)
      tracker.record_reopen(at: earlier_at)

      expect(episodes.map { |episode| [episode.started_at, episode.ended_at] }).to eq(
        [[initial_at, earlier_at], [earlier_at, later_at], [later_at, nil]]
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

    it 'moves a resolution recorded before a late boundary into the covering episode' do
      resolved_at = 2.minutes.ago
      tracker.record_resolution(at: resolved_at)

      tracker.record_reopen(at: 10.minutes.ago)

      expect(initial.reload.resolved_at).to be_nil
      expect(episodes.last.resolved_at).to eq(resolved_at)
    end

    it 'recounts captain replies per window when a late boundary splits them' do
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       sender: assistant, message_type: :outgoing, created_at: 20.minutes.ago)
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       sender: assistant, message_type: :outgoing, created_at: 2.minutes.ago)
      described_class.new(conversation: conversation).record_captain_reply(
        message: conversation.messages.last
      )

      tracker.record_reopen(at: 10.minutes.ago)

      expect(initial.reload.captain_reply_count).to eq(1)
      expect(episodes.last.captain_reply_count).to eq(1)
    end
  end

  describe '#record_captain_reply' do
    let!(:initial) { tracker.record_eligibility(at: 30.minutes.ago) }

    it 'recounts replies within the attributed episode window' do
      message = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: assistant, message_type: :outgoing, created_at: 20.minutes.ago
      )

      tracker.record_captain_reply(message: message)

      expect(initial.reload).to have_attributes(
        captain_reply_count: 1,
        first_captain_reply_at: message.created_at,
        last_captain_reply_at: message.created_at
      )
    end

    it 'updates a closed episode when the reply is delivered late' do
      tracker.record_reopen(at: 10.minutes.ago)
      message = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: assistant, message_type: :outgoing, created_at: 20.minutes.ago
      )

      tracker.record_captain_reply(message: message)

      expect(initial.reload.captain_reply_count).to eq(1)
      expect(episodes.last.captain_reply_count).to eq(0)
    end

    it 'ignores private captain notes' do
      message = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: assistant, message_type: :outgoing, private: true
      )

      tracker.record_captain_reply(message: message)

      expect(initial.reload.captain_reply_count).to eq(0)
    end
  end

  describe '#record_handoff' do
    let!(:initial) { tracker.record_eligibility(at: 30.minutes.ago) }

    it 'preserves the first handoff and its reason category within the episode' do
      first_handoff_at = 2.minutes.ago
      tracker.record_handoff(at: first_handoff_at, reason_category: 'missing_knowledge')

      tracker.record_handoff(at: Time.current, reason_category: 'unsupported_request')

      expect(initial.reload).to have_attributes(
        handoff_at: first_handoff_at,
        handoff_reason_category: 'missing_knowledge'
      )
    end

    it 'converges to the earliest handoff when events arrive out of order' do
      earliest_handoff_at = 5.minutes.ago
      tracker.record_handoff(at: 2.minutes.ago, reason_category: 'unsupported_request')

      tracker.record_handoff(at: earliest_handoff_at, reason_category: 'missing_knowledge')

      expect(initial.reload).to have_attributes(
        handoff_at: earliest_handoff_at,
        handoff_reason_category: 'missing_knowledge'
      )
    end
  end

  describe '#record_human_reply' do
    let!(:initial) { tracker.record_eligibility(at: 30.minutes.ago) }

    it 'records the first public human reply' do
      agent = create(:user, account: account)
      message = create(
        :message,
        account: account, inbox: inbox, conversation: conversation,
        sender: agent, message_type: :outgoing, created_at: 5.minutes.ago
      )

      tracker.record_human_reply(message: message)

      expect(initial.reload.first_human_reply_at).to eq(message.created_at)
    end
  end

  describe '#record_resolution' do
    let!(:initial) { tracker.record_eligibility(at: 30.minutes.ago) }

    it 'attributes a delayed resolution to the episode active at its event time' do
      tracker.record_reopen(at: 10.minutes.ago)

      resolved_at = 20.minutes.ago
      tracker.record_resolution(at: resolved_at)

      expect(initial.reload.resolved_at).to eq(resolved_at)
      expect(episodes.last.resolved_at).to be_nil
    end

    it 'preserves the latest resolution within an episode' do
      latest_resolution_at = Time.current
      tracker.record_resolution(at: latest_resolution_at)

      tracker.record_resolution(at: 1.minute.ago)

      expect(initial.reload.resolved_at).to eq(latest_resolution_at)
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
