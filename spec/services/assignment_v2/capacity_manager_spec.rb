# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Enterprise::AssignmentV2::CapacityManager do
  let(:manager) { described_class.new }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:capacity_policy) { create(:enterprise_agent_capacity_policy, account: account) }
  let!(:account_user) { create(:account_user, account: account, user: agent, agent_capacity_policy: capacity_policy) }

  before do
    # Clear any existing cache
    Rails.cache.clear
  end

  describe '#get_agent_capacity' do
    context 'with capacity policy and limits' do
      let!(:inbox_limit) { create(:enterprise_inbox_capacity_limit, agent_capacity_policy: capacity_policy, inbox: inbox, conversation_limit: 10) }

      it 'returns correct capacity data' do
        capacity = manager.get_agent_capacity(agent, inbox)
        
        expect(capacity).to include(
          total_capacity: 10,
          current_assignments: 0,
          available_capacity: 10,
          policy_id: capacity_policy.id,
          has_policy: true
        )
      end

      it 'counts only open conversations' do
        # Create conversations with different statuses
        create_list(:conversation, 3, inbox: inbox, assignee: agent, status: :open)
        create_list(:conversation, 2, inbox: inbox, assignee: agent, status: :resolved)
        create(:conversation, inbox: inbox, assignee: agent, status: :snoozed)
        
        capacity = manager.get_agent_capacity(agent, inbox)
        
        expect(capacity[:current_assignments]).to eq(3)
        expect(capacity[:available_capacity]).to eq(7)
      end

      it 'caches capacity data' do
        # First call
        manager.get_agent_capacity(agent, inbox)
        
        # Second call should use cache
        expect(Rails.cache).to receive(:fetch).and_call_original
        manager.get_agent_capacity(agent, inbox)
      end

      it 'respects cache TTL' do
        cache_key = "assignment_v2:capacity:#{agent.accounts.first.id}:#{agent.id}:#{inbox.id}"
        
        manager.get_agent_capacity(agent, inbox)
        
        # Check cache exists with TTL
        expect(Rails.cache.exist?(cache_key)).to be true
      end
    end

    context 'without capacity policy' do
      before { account_user.update!(agent_capacity_policy: nil) }

      it 'returns unlimited capacity' do
        capacity = manager.get_agent_capacity(agent, inbox)
        
        expect(capacity).to include(
          total_capacity: 999_999,
          current_assignments: 0,
          available_capacity: 999_999,
          policy_id: nil,
          has_policy: false
        )
      end
    end

    context 'without inbox limit' do
      it 'returns unlimited capacity' do
        capacity = manager.get_agent_capacity(agent, inbox)
        
        expect(capacity[:has_policy]).to be false
        expect(capacity[:available_capacity]).to eq(999_999)
      end
    end

    context 'with exclusion rules' do
      let(:excluded_label) { create(:label, account: account, title: 'vip') }
      let(:capacity_policy) do
        create(:enterprise_agent_capacity_policy,
               account: account,
               exclusion_rules: {
                 'labels' => ['vip'],
                 'hours_threshold' => 24
               })
      end
      let!(:inbox_limit) { create(:enterprise_inbox_capacity_limit, agent_capacity_policy: capacity_policy, inbox: inbox, conversation_limit: 10) }

      it 'excludes conversations with specified labels' do
        # Create regular conversations
        create_list(:conversation, 3, inbox: inbox, assignee: agent, status: :open)
        
        # Create VIP conversations (should be excluded)
        vip_conversations = create_list(:conversation, 2, inbox: inbox, assignee: agent, status: :open)
        vip_conversations.each { |conv| create(:conversation_label, conversation: conv, label: excluded_label) }
        
        capacity = manager.get_agent_capacity(agent, inbox)
        
        expect(capacity[:current_assignments]).to eq(3) # Only non-VIP conversations
      end

      it 'excludes old conversations based on hours threshold' do
        # Create recent conversations
        create_list(:conversation, 2, inbox: inbox, assignee: agent, status: :open, created_at: 1.hour.ago)
        
        # Create old conversations (should be excluded)
        create_list(:conversation, 3, inbox: inbox, assignee: agent, status: :open, created_at: 2.days.ago)
        
        capacity = manager.get_agent_capacity(agent, inbox)
        
        expect(capacity[:current_assignments]).to eq(2) # Only recent conversations
      end
    end

    context 'error handling' do
      it 'returns unlimited capacity on error' do
        allow(Rails.cache).to receive(:fetch).and_raise(StandardError, 'Cache error')
        expect(Rails.logger).to receive(:error).with(/Capacity manager failed/)
        
        capacity = manager.get_agent_capacity(agent, inbox)
        
        expect(capacity[:has_policy]).to be false
        expect(capacity[:available_capacity]).to eq(999_999)
      end
    end
  end

  describe '#get_agents_capacity_status' do
    let(:agent2) { create(:user, account: account, role: :agent) }
    let!(:account_user2) { create(:account_user, account: account, user: agent2) }

    it 'returns capacity status for multiple agents' do
      agents = [agent, agent2]
      
      statuses = manager.get_agents_capacity_status(agents, inbox)
      
      expect(statuses.length).to eq(2)
      expect(statuses[0][:agent]).to eq(agent)
      expect(statuses[1][:agent]).to eq(agent2)
    end
  end

  describe '#agent_has_capacity?' do
    let!(:inbox_limit) { create(:enterprise_inbox_capacity_limit, agent_capacity_policy: capacity_policy, inbox: inbox, conversation_limit: 2) }

    context 'when agent has capacity' do
      it 'returns true' do
        create(:conversation, inbox: inbox, assignee: agent, status: :open)
        
        expect(manager.agent_has_capacity?(agent, inbox)).to be true
      end
    end

    context 'when agent is at capacity' do
      it 'returns false' do
        create_list(:conversation, 2, inbox: inbox, assignee: agent, status: :open)
        
        expect(manager.agent_has_capacity?(agent, inbox)).to be false
      end
    end
  end

  describe '#get_remaining_capacity' do
    let!(:inbox_limit) { create(:enterprise_inbox_capacity_limit, agent_capacity_policy: capacity_policy, inbox: inbox, conversation_limit: 5) }

    it 'returns correct remaining capacity' do
      create_list(:conversation, 3, inbox: inbox, assignee: agent, status: :open)
      
      expect(manager.get_remaining_capacity(agent, inbox)).to eq(2)
    end

    it 'returns 0 when over capacity' do
      create_list(:conversation, 6, inbox: inbox, assignee: agent, status: :open)
      
      expect(manager.get_remaining_capacity(agent, inbox)).to eq(0)
    end
  end

  describe '#invalidate_agent_capacity_cache' do
    it 'clears specific inbox cache when inbox provided' do
      cache_key = "assignment_v2:capacity:#{agent.accounts.first.id}:#{agent.id}:#{inbox.id}"
      Rails.cache.write(cache_key, 'test_data')
      
      manager.invalidate_agent_capacity_cache(agent, inbox)
      
      expect(Rails.cache.read(cache_key)).to be_nil
    end

    it 'clears all agent caches when inbox not provided' do
      cache_key1 = "assignment_v2:capacity:#{agent.id}:inbox1"
      cache_key2 = "assignment_v2:capacity:#{agent.id}:inbox2"
      
      Rails.cache.write(cache_key1, 'test_data')
      Rails.cache.write(cache_key2, 'test_data')
      
      expect(Rails.cache).to receive(:delete_matched).with("assignment_v2:capacity:#{agent.id}:*")
      
      manager.invalidate_agent_capacity_cache(agent)
    end
  end

  describe '#invalidate_inbox_capacity_cache' do
    it 'clears all capacity caches for inbox' do
      expect(Rails.cache).to receive(:delete_matched).with("assignment_v2:capacity:*:#{inbox.id}")
      
      manager.invalidate_inbox_capacity_cache(inbox)
    end
  end

  describe 'edge cases' do
    it 'handles agent without account correctly' do
      agent_without_account = create(:user, role: :agent)
      
      capacity = manager.get_agent_capacity(agent_without_account, inbox)
      
      expect(capacity[:has_policy]).to be false
    end

    it 'handles multiple capacity policies gracefully' do
      # Create another policy and try to assign it
      another_policy = create(:enterprise_agent_capacity_policy, account: account)
      
      # Update account user
      account_user.update!(agent_capacity_policy: another_policy)
      
      # Should use the new policy
      capacity = manager.get_agent_capacity(agent, inbox)
      expect(capacity[:policy_id]).to eq(another_policy.id)
    end

    it 'handles conversations from different inboxes' do
      other_inbox = create(:inbox, account: account)
      inbox_limit = create(:enterprise_inbox_capacity_limit, 
                          agent_capacity_policy: capacity_policy, 
                          inbox: inbox, 
                          conversation_limit: 5)
      
      # Create conversations in different inboxes
      create_list(:conversation, 3, inbox: inbox, assignee: agent, status: :open)
      create_list(:conversation, 10, inbox: other_inbox, assignee: agent, status: :open)
      
      # Should only count conversations from specified inbox
      capacity = manager.get_agent_capacity(agent, inbox)
      expect(capacity[:current_assignments]).to eq(3)
    end
  end
end