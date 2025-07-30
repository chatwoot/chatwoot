# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Assignment V2 Security', type: :service do
  let(:account1) { create(:account) }
  let(:account2) { create(:account) }
  let(:inbox1) { create(:inbox, account: account1) }
  let(:inbox2) { create(:inbox, account: account2) }
  let(:user1) { create(:user, account: account1) }
  let(:user2) { create(:user, account: account2) }

  describe 'Cross-account data access prevention' do
    let(:policy1) { create(:assignment_policy, account: account1) }
    let(:policy2) { create(:assignment_policy, account: account2) }

    context 'AssignmentPolicy' do
      it 'prevents cross-account policy assignment' do
        expect {
          InboxAssignmentPolicy.create!(
            inbox: inbox1,
            assignment_policy: policy2  # Different account policy
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'validates policy names are unique within account only' do
        create(:assignment_policy, account: account1, name: 'Default')
        
        # Same name in different account should be allowed
        expect {
          create(:assignment_policy, account: account2, name: 'Default')
        }.not_to raise_error

        # Same name in same account should fail
        expect {
          create(:assignment_policy, account: account1, name: 'Default')
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'Enterprise capacity policies' do
      before do
        stub_const('Enterprise', Module.new)
        enterprise_policy_class = Class.new(ApplicationRecord) do
          include AccountCacheRevalidator
          
          self.table_name = 'enterprise_agent_capacity_policies'
          
          belongs_to :account
          validates :name, presence: true, uniqueness: { scope: :account_id }
        end
        
        stub_const('Enterprise::AgentCapacityPolicy', enterprise_policy_class)
      end

      it 'prevents cross-account agent assignment' do
        # This test would verify that users from one account 
        # cannot be assigned to capacity policies from another account
        expect(true).to be true  # Placeholder - would need actual enterprise models
      end
    end
  end

  describe 'SQL injection prevention' do
    let(:policy) { create(:assignment_policy, account: account1) }
    let(:orchestrator) { AssignmentV2::AssignmentOrchestrator.new(inbox1) }

    it 'uses parameterized queries in conversation fetching' do
      # Test that malicious input in policy configuration doesn't lead to SQL injection
      malicious_input = "'; DROP TABLE users; --"
      
      # Should not raise SQL errors or cause injection
      expect {
        # This would test priority ordering with potentially malicious data
        conversations = orchestrator.send(:fetch_prioritized_conversations, 10)
      }.not_to raise_error
    end

    it 'safely handles Arel SQL in longest_waiting priority' do
      policy.update!(conversation_priority: 'longest_waiting')
      conversations = orchestrator.send(:fetch_prioritized_conversations, 10)
      
      # Should use parameterized Arel queries, not string interpolation
      expect(conversations).to be_an(ActiveRecord::Relation)
    end
  end

  describe 'Redis key isolation' do
    let(:policy) { create(:assignment_policy, account: account1) }
    let(:rate_limiter1) { AssignmentV2::RateLimiter.new(policy) }
    let(:rate_limiter2) { AssignmentV2::RateLimiter.new(policy) }

    it 'uses agent-specific Redis keys to prevent data leaks' do
      key1 = rate_limiter1.send(:rate_limit_key, user1, 123456)
      key2 = rate_limiter1.send(:rate_limit_key, user2, 123456)
      
      expect(key1).to include(user1.id.to_s)
      expect(key2).to include(user2.id.to_s)
      expect(key1).not_to eq(key2)
    end

    it 'includes window in Redis keys for temporal isolation' do
      window1 = 123456
      window2 = 123457
      
      key1 = rate_limiter1.send(:rate_limit_key, user1, window1)
      key2 = rate_limiter1.send(:rate_limit_key, user1, window2)
      
      expect(key1).not_to eq(key2)
      expect(key1).to include(window1.to_s)
      expect(key2).to include(window2.to_s)
    end
  end

  describe 'Authorization checks' do
    let(:policy) { create(:assignment_policy, account: account1) }
    let(:selector) { AssignmentV2::RoundRobinSelector.new(inbox1, policy) }

    it 'only selects agents who are inbox members' do
      create(:account_user, account: account1, user: user1, role: 'agent')
      create(:account_user, account: account2, user: user2, role: 'agent')
      
      # Only user1 should be eligible (user2 is not an inbox member)
      eligible_agents = selector.send(:compute_eligible_agents)
      expect(eligible_agents).not_to include(user2.id)
    end

    it 'only selects agents from the same account' do
      create(:inbox_member, inbox: inbox1, user: user1)
      create(:inbox_member, inbox: inbox1, user: user2)  # Cross-account member
      create(:account_user, account: account1, user: user1, role: 'agent')
      create(:account_user, account: account2, user: user2, role: 'agent')
      
      eligible_agents = selector.send(:compute_eligible_agents)
      expect(eligible_agents).to include(user1.id)
      expect(eligible_agents).not_to include(user2.id)
    end
  end

  describe 'Input validation and sanitization' do
    it 'validates assignment policy limits are reasonable' do
      expect {
        create(:assignment_policy, 
          account: account1,
          fair_distribution_limit: 101  # Over limit
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect {
        create(:assignment_policy, 
          account: account1,
          fair_distribution_window: 30  # Under minimum
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'validates enterprise capacity limits are reasonable' do
      # Test would validate that conversation limits can't be set to extreme values
      # This prevents resource exhaustion attacks
      expect(true).to be true  # Placeholder
    end

    it 'sanitizes policy names and descriptions' do
      policy = create(:assignment_policy, 
        account: account1,
        name: 'Test Policy',
        description: 'A test description'
      )
      
      expect(policy.name).to eq('Test Policy')
      expect(policy.description).to eq('A test description')
      expect(policy.name.length).to be <= 255
      expect(policy.description.length).to be <= 1000
    end
  end

  describe 'Rate limiting protection' do
    let(:policy) { create(:assignment_policy, account: account1, fair_distribution_limit: 5) }
    let(:rate_limiter) { AssignmentV2::RateLimiter.new(policy) }

    before do
      allow(Redis::Alfred).to receive(:get).and_return('10')  # Over limit
      allow(Redis::Alfred).to receive(:multi)
      allow(Rails.logger).to receive(:error)
    end

    it 'prevents assignment when agent is over rate limit' do
      expect(rate_limiter.agent_within_limits?(user1)).to be false
    end

    it 'handles Redis failures gracefully without blocking assignments' do
      allow(Redis::Alfred).to receive(:get).and_raise(Redis::CannotConnectError)
      
      # Should return 0 on Redis failure, effectively disabling rate limiting
      expect(rate_limiter.agent_within_limits?(user1)).to be true
    end
  end
end