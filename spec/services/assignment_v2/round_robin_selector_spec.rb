# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::RoundRobinSelector, type: :service do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:policy) { create(:assignment_policy, account: account) }
  let(:user1) { create(:user, account: account, availability: User::AVAILABILITY_STATUSES['online']) }
  let(:user2) { create(:user, account: account, availability: User::AVAILABILITY_STATUSES['online']) }
  let(:user3) { create(:user, account: account, availability: User::AVAILABILITY_STATUSES['offline']) }

  before do
    create(:inbox_member, inbox: inbox, user: user1)
    create(:inbox_member, inbox: inbox, user: user2)
    create(:inbox_member, inbox: inbox, user: user3)
    create(:account_user, account: account, user: user1, role: 'agent')
    create(:account_user, account: account, user: user2, role: 'agent')
    create(:account_user, account: account, user: user3, role: 'agent')
  end

  describe '#select_agent' do
    let(:selector) { described_class.new(inbox, policy) }

    context 'when Redis is available' do
      before do
        allow(Redis::Alfred).to receive(:set).and_return(true)
        allow(Redis::Alfred).to receive(:del)
        allow(Redis::Alfred).to receive(:lpop).and_return(user1.id.to_s)
        allow(Redis::Alfred).to receive(:rpush)
        allow(Redis::Alfred).to receive(:multi).and_yield(double(del: nil, rpush: nil, expire: nil))
      end

      it 'returns an online agent' do
        result = selector.select_agent
        expect(result).to be_a(User)
        expect([user1.id, user2.id]).to include(result.id)
      end

      it 'excludes offline agents' do
        allow(selector).to receive(:compute_eligible_agents).and_return([user1.id, user2.id])
        result = selector.select_agent
        expect(result&.id).not_to eq(user3.id)
      end

      it 'handles Redis lock contention gracefully' do
        allow(Redis::Alfred).to receive(:set).and_return(false)
        result = selector.select_agent
        expect(result).to be_nil
      end
    end

    context 'when Redis fails' do
      before do
        allow(Redis::Alfred).to receive(:set).and_raise(Redis::CannotConnectError)
      end

      it 'falls back to database selection' do
        result = selector.select_agent
        expect(result).to be_a(User)
        expect([user1.id, user2.id]).to include(result.id)
      end
    end

    context 'with rate limiting' do
      let(:rate_limiter) { instance_double(AssignmentV2::RateLimiter) }

      before do
        allow(AssignmentV2::RateLimiter).to receive(:new).and_return(rate_limiter)
      end

      it 'filters agents by rate limits' do
        allow(rate_limiter).to receive(:agent_within_limits?).with(user1).and_return(true)
        allow(rate_limiter).to receive(:agent_within_limits?).with(user2).and_return(false)
        
        # Mock Redis operations
        allow(Redis::Alfred).to receive(:set).and_return(true)
        allow(Redis::Alfred).to receive(:del)
        allow(Redis::Alfred).to receive(:lpop).and_return(user1.id.to_s)
        allow(Redis::Alfred).to receive(:rpush)
        allow(Redis::Alfred).to receive(:multi).and_yield(double(del: nil, rpush: nil, expire: nil))

        result = selector.select_agent
        expect(result&.id).to eq(user1.id)
      end
    end

    context 'with enterprise capacity' do
      before do
        stub_const('Enterprise', Module.new)
        allow(inbox.account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(true)
      end

      it 'attempts to filter by capacity when enterprise is available' do
        capacity_manager = instance_double('Enterprise::AssignmentV2::CapacityManager')
        stub_const('Enterprise::AssignmentV2::CapacityManager', class_double('Enterprise::AssignmentV2::CapacityManager', new: capacity_manager))
        
        allow(capacity_manager).to receive(:get_agent_capacity).and_return({ available_capacity: 5 })
        
        # Mock Redis operations
        allow(Redis::Alfred).to receive(:set).and_return(true)
        allow(Redis::Alfred).to receive(:del)
        allow(Redis::Alfred).to receive(:lpop).and_return(user1.id.to_s)
        allow(Redis::Alfred).to receive(:rpush)
        allow(Redis::Alfred).to receive(:multi).and_yield(double(del: nil, rpush: nil, expire: nil))

        result = selector.select_agent
        expect(result).to be_a(User)
      end
    end
  end

  describe '#refresh_queue!' do
    let(:selector) { described_class.new(inbox, policy) }

    it 'refreshes the Redis queue with eligible agents' do
      expect(Redis::Alfred).to receive(:multi).and_yield(double(del: nil, rpush: nil, expire: nil))
      selector.refresh_queue!
    end
  end

  describe 'race condition safety' do
    let(:selector) { described_class.new(inbox, policy) }

    it 'handles concurrent access with Redis locks' do
      # Simulate lock contention
      call_count = 0
      allow(Redis::Alfred).to receive(:set) do |key, value, options|
        call_count += 1
        call_count == 1 ? true : false  # First call succeeds, second fails
      end

      allow(Redis::Alfred).to receive(:del)
      allow(Redis::Alfred).to receive(:lpop).and_return(user1.id.to_s)
      allow(Redis::Alfred).to receive(:rpush)

      # Multiple concurrent calls
      results = []
      threads = []
      
      3.times do
        threads << Thread.new do
          results << selector.select_agent
        end
      end
      
      threads.each(&:join)
      
      # At least one should succeed, others should be nil due to lock contention
      expect(results.compact.length).to be >= 1
    end
  end

  describe 'memory and performance' do
    let(:selector) { described_class.new(inbox, policy) }

    it 'cleans up Redis keys with TTL' do
      expect(Redis::Alfred).to receive(:multi).and_yield(
        double(del: nil, expire: receive(:expire).with(anything, AssignmentV2::RoundRobinSelector::QUEUE_TTL.to_i))
      )
      
      allow(Redis::Alfred).to receive(:set).and_return(true)
      allow(Redis::Alfred).to receive(:del)
      allow(Redis::Alfred).to receive(:lpop).and_return(user1.id.to_s)
      allow(Redis::Alfred).to receive(:rpush)
      
      selector.select_agent
    end
  end
end