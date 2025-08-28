require 'rails_helper'

RSpec.describe AutoAssignment::AssignmentService do
  let(:account) { create(:account) }
  let(:inbox) do
    create(:inbox,
           account: account,
           enable_auto_assignment: true,
           auto_assignment_config: {
             'fair_distribution_limit' => 2,
             'fair_distribution_window' => 3600
           })
  end
  let(:service) { described_class.new(inbox: inbox) }
  let(:agent1) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent2) { create(:user, account: account, role: :agent, availability: :online) }

  before do
    create(:inbox_member, inbox: inbox, user: agent1)
    create(:inbox_member, inbox: inbox, user: agent2)
    allow(OnlineStatusTracker).to receive(:get_available_users)
      .and_return({
                    agent1.id.to_s => 'online',
                    agent2.id.to_s => 'online'
                  })
    # Clean up Redis keys for this inbox
    clean_redis_keys
  end

  after do
    clean_redis_keys
  end

  def clean_redis_keys
    # Clean up assignment keys for both agents
    pattern1 = "assignment:#{inbox.id}:agent:#{agent1.id}:*"
    pattern2 = "assignment:#{inbox.id}:agent:#{agent2.id}:*"

    Redis::Alfred.scan_each(match: pattern1) { |key| Redis::Alfred.delete(key) }
    Redis::Alfred.scan_each(match: pattern2) { |key| Redis::Alfred.delete(key) }
  end

  def create_test_conversation
    conversation = build(:conversation, inbox: inbox, assignee: nil, status: :open)
    allow(conversation).to receive(:run_auto_assignment).and_return(nil)
    conversation.save!
    conversation
  end

  describe 'with fair distribution enabled' do
    it 'respects the assignment limit per agent' do
      # Each agent can handle 2 conversations
      conversations = Array.new(4) { create_test_conversation }

      # First 4 conversations should be assigned (2 per agent)
      conversations.each do |conv|
        expect(service.perform_for_conversation(conv)).to be true
      end

      # Verify distribution
      assigned_to_agent1 = conversations.count { |c| c.reload.assignee == agent1 }
      assigned_to_agent2 = conversations.count { |c| c.reload.assignee == agent2 }

      expect(assigned_to_agent1).to eq(2)
      expect(assigned_to_agent2).to eq(2)

      # Fifth conversation should fail (both agents at limit)
      fifth_conversation = create_test_conversation
      expect(service.perform_for_conversation(fifth_conversation)).to be false
      expect(fifth_conversation.reload.assignee).to be_nil
    end

    it 'tracks assignments using individual Redis keys' do
      conversation = create_test_conversation
      service.perform_for_conversation(conversation)

      # Check that assignment key exists
      pattern = "assignment:#{inbox.id}:agent:#{conversation.reload.assignee.id}:*"
      count = Redis::Alfred.keys_count(pattern)
      expect(count).to eq(1)
    end

    it 'allows new assignments after window expires' do
      # Assign 2 conversations to agent1
      2.times do
        conversation = create_test_conversation
        allow(service).to receive(:round_robin_selector).and_return(
          instance_double(AutoAssignment::RoundRobinSelector, select_agent: agent1)
        )
        service.perform_for_conversation(conversation)
      end

      # Agent1 is now at limit
      rate_limiter = AutoAssignment::RateLimiter.new(inbox: inbox, agent: agent1)
      expect(rate_limiter.within_limit?).to be false

      # Clear Redis keys to simulate time window expiry
      clean_redis_keys

      # Agent1 should be available again
      expect(rate_limiter.within_limit?).to be true

      # New assignment should work
      new_conversation = create_test_conversation
      allow(service).to receive(:round_robin_selector).and_return(
        instance_double(AutoAssignment::RoundRobinSelector, select_agent: agent1)
      )
      expect(service.perform_for_conversation(new_conversation)).to be true
    end
  end

  describe 'without fair distribution' do
    before do
      inbox.update!(auto_assignment_config: {})
    end

    it 'assigns without limits' do
      # Create more conversations than would be allowed with limits
      5.times do
        conversation = create_test_conversation
        expect(service.perform_for_conversation(conversation)).to be true
        expect(conversation.reload.assignee).not_to be_nil
      end
    end
  end
end
