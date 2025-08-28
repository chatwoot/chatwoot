require 'rails_helper'

RSpec.describe AutoAssignment::AssignmentService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true) }
  let(:service) { described_class.new(inbox: inbox) }
  let(:agent) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent2) { create(:user, account: account, role: :agent, availability: :online) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
  end

  def create_test_conversation(attrs = {})
    conversation = build(:conversation, attrs.reverse_merge(inbox: inbox, assignee: nil))
    # Skip the after_save callback to test our service directly
    allow(conversation).to receive(:run_auto_assignment).and_return(nil)
    conversation.save!
    conversation
  end

  describe '#perform_for_conversation' do
    let(:conversation) { create_test_conversation }

    before do
      allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agent.id.to_s => 'online' })
    end

    context 'when auto assignment is enabled' do
      it 'assigns conversation to available agent' do
        expect(service.perform_for_conversation(conversation)).to be true
        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'dispatches assignee changed event' do
        # The conversation update triggers its own event through callbacks
        allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original

        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          Events::Types::ASSIGNEE_CHANGED,
          anything,
          hash_including(conversation: conversation, user: agent)
        )

        service.perform_for_conversation(conversation)
      end

      it 'returns false when no agents available' do
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({})
        expect(service.perform_for_conversation(conversation)).to be false
      end
    end

    context 'when conversation already assigned' do
      let(:conversation) { create_test_conversation(assignee: agent) }

      it 'does not reassign' do
        expect(service.perform_for_conversation(conversation)).to be false
      end
    end

    context 'when conversation is not open' do
      let(:conversation) { create_test_conversation(status: 'resolved') }

      it 'does not assign' do
        expect(service.perform_for_conversation(conversation)).to be false
      end
    end
  end

  describe '#perform_bulk_assignment' do
    before do
      allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agent.id.to_s => 'online' })
      3.times { create_test_conversation(status: :open) }
    end

    it 'assigns multiple conversations' do
      assigned_count = service.perform_bulk_assignment(limit: 2)
      expect(assigned_count).to eq(2)
    end

    it 'respects the limit parameter' do
      assigned_count = service.perform_bulk_assignment(limit: 1)
      expect(assigned_count).to eq(1)
      expect(inbox.conversations.unassigned.count).to eq(2)
    end

    context 'when auto assignment disabled' do
      before { inbox.update!(enable_auto_assignment: false) }

      it 'returns 0' do
        expect(service.perform_bulk_assignment).to eq(0)
      end
    end
  end

  describe 'with rate limiting' do
    let(:rate_limiter) { instance_double(AutoAssignment::RateLimiter) }

    before do
      create(:inbox_member, inbox: inbox, user: agent2)
      allow(OnlineStatusTracker).to receive(:get_available_users).and_return({
                                                                               agent.id.to_s => 'online',
                                                                               agent2.id.to_s => 'online'
                                                                             })
      allow(inbox).to receive(:auto_assignment_config).and_return({
                                                                    'fair_distribution_limit' => 2,
                                                                    'fair_distribution_window' => 3600
                                                                  })
    end

    it 'filters agents based on rate limits' do
      # Agent 1 has reached limit
      rate_limiter_agent1 = instance_double(AutoAssignment::RateLimiter, within_limit?: false)
      allow(AutoAssignment::RateLimiter).to receive(:new)
        .with(inbox: inbox, agent: agent)
        .and_return(rate_limiter_agent1)

      # Agent 2 is within limit
      rate_limiter_agent2 = instance_double(AutoAssignment::RateLimiter, within_limit?: true, track_assignment: true)
      allow(AutoAssignment::RateLimiter).to receive(:new)
        .with(inbox: inbox, agent: agent2)
        .and_return(rate_limiter_agent2)

      conversation = create_test_conversation

      expect(service.perform_for_conversation(conversation)).to be true
      expect(conversation.reload.assignee).to eq(agent2)
    end

    it 'tracks assignments in Redis' do
      conversation = create_test_conversation

      rate_limiter = instance_double(AutoAssignment::RateLimiter, within_limit?: true)
      allow(AutoAssignment::RateLimiter).to receive(:new).and_return(rate_limiter)

      expect(rate_limiter).to receive(:track_assignment).with(conversation)

      service.perform_for_conversation(conversation)
    end
  end

  describe 'conversation priority' do
    before do
      allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agent.id.to_s => 'online' })
    end

    context 'with longest_waiting priority' do
      let!(:old_conversation) do
        create_test_conversation(status: :open, created_at: 2.hours.ago, last_activity_at: 2.hours.ago)
      end
      let!(:new_conversation) do
        create_test_conversation(status: :open, created_at: 1.hour.ago, last_activity_at: 1.hour.ago)
      end

      before do
        allow(inbox).to receive(:auto_assignment_config).and_return({
                                                                      'conversation_priority' => 'longest_waiting'
                                                                    })
      end

      it 'assigns oldest conversation first' do
        service.perform_bulk_assignment(limit: 1)

        expect(old_conversation.reload.assignee).to eq(agent)
        expect(new_conversation.reload.assignee).to be_nil
      end
    end

    context 'with default priority' do
      let!(:first_created) do
        create_test_conversation(status: :open, created_at: 2.hours.ago)
      end
      let!(:second_created) do
        create_test_conversation(status: :open, created_at: 1.hour.ago)
      end

      it 'assigns by creation time' do
        service.perform_bulk_assignment(limit: 1)

        expect(first_created.reload.assignee).to eq(agent)
        expect(second_created.reload.assignee).to be_nil
      end
    end
  end
end
