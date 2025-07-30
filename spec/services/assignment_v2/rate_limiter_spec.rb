# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::RateLimiter, type: :service do
  let(:account) { create(:account) }
  let(:policy) { create(:assignment_policy, account: account, fair_distribution_limit: 5, fair_distribution_window: 3600) }
  let(:agent) { create(:user, account: account) }
  let(:rate_limiter) { described_class.new(policy) }

  before do
    # Clear Redis state
    Redis::Alfred.flushdb
  end

  describe '#initialize' do
    it 'sets up rate limiter with policy parameters' do
      expect(rate_limiter.instance_variable_get(:@limit)).to eq(5)
      expect(rate_limiter.instance_variable_get(:@window_size)).to eq(3600)
    end
  end

  describe '#agent_within_limits?' do
    context 'when agent has no assignments in current window' do
      it 'returns true' do
        expect(rate_limiter.agent_within_limits?(agent)).to be true
      end
    end

    context 'when agent is below limit' do
      before do
        # Simulate 3 assignments in current window
        3.times { rate_limiter.increment_agent_assignments(agent) }
      end

      it 'returns true' do
        expect(rate_limiter.agent_within_limits?(agent)).to be true
      end
    end

    context 'when agent reaches limit' do
      before do
        # Simulate reaching the limit (5 assignments)
        5.times { rate_limiter.increment_agent_assignments(agent) }
      end

      it 'returns false' do
        expect(rate_limiter.agent_within_limits?(agent)).to be false
      end
    end

    context 'when agent exceeds limit' do
      before do
        # Simulate exceeding the limit
        6.times { rate_limiter.increment_agent_assignments(agent) }
      end

      it 'returns false' do
        expect(rate_limiter.agent_within_limits?(agent)).to be false
      end
    end
  end

  describe '#increment_agent_assignments' do
    it 'increments assignment count for agent' do
      expect { rate_limiter.increment_agent_assignments(agent) }
        .to change { rate_limiter.get_agent_assignment_count(agent) }.from(0).to(1)
    end

    it 'sets expiration on the key' do
      rate_limiter.increment_agent_assignments(agent)
      
      current_window = Time.current.to_i / 3600
      key = "assignment_v2:rate_limit:#{agent.id}:#{current_window}"
      
      ttl = Redis::Alfred.ttl(key)
      expect(ttl).to be > 0
      expect(ttl).to be <= 3600
    end

    context 'when Redis fails' do
      before do
        allow(Redis::Alfred).to receive(:multi).and_raise(Redis::ConnectionError)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and continues without raising' do
        expect { rate_limiter.increment_agent_assignments(agent) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Rate limiter increment failed/)
      end
    end
  end

  describe '#get_agent_assignment_count' do
    it 'returns 0 for agent with no assignments' do
      expect(rate_limiter.get_agent_assignment_count(agent)).to eq(0)
    end

    it 'returns correct count after assignments' do
      3.times { rate_limiter.increment_agent_assignments(agent) }
      expect(rate_limiter.get_agent_assignment_count(agent)).to eq(3)
    end

    context 'when Redis fails' do
      before do
        allow(Redis::Alfred).to receive(:get).and_raise(Redis::ConnectionError)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns 0 and logs error' do
        expect(rate_limiter.get_agent_assignment_count(agent)).to eq(0)
        expect(Rails.logger).to have_received(:error).with(/Rate limiter get count failed/)
      end
    end
  end

  describe '#get_remaining_assignments' do
    it 'returns full limit when no assignments made' do
      expect(rate_limiter.get_remaining_assignments(agent)).to eq(5)
    end

    it 'returns correct remaining count' do
      2.times { rate_limiter.increment_agent_assignments(agent) }
      expect(rate_limiter.get_remaining_assignments(agent)).to eq(3)
    end

    it 'returns 0 when limit reached' do
      5.times { rate_limiter.increment_agent_assignments(agent) }
      expect(rate_limiter.get_remaining_assignments(agent)).to eq(0)
    end

    it 'returns 0 when limit exceeded' do
      6.times { rate_limiter.increment_agent_assignments(agent) }
      expect(rate_limiter.get_remaining_assignments(agent)).to eq(0)
    end
  end

  describe '#can_assign_to_agent?' do
    it 'returns true when agent has remaining capacity' do
      2.times { rate_limiter.increment_agent_assignments(agent) }
      expect(rate_limiter.can_assign_to_agent?(agent)).to be true
    end

    it 'returns false when agent has no capacity' do
      5.times { rate_limiter.increment_agent_assignments(agent) }
      expect(rate_limiter.can_assign_to_agent?(agent)).to be false
    end

    it 'checks for specific count requirement' do
      3.times { rate_limiter.increment_agent_assignments(agent) }
      
      expect(rate_limiter.can_assign_to_agent?(agent, 1)).to be true
      expect(rate_limiter.can_assign_to_agent?(agent, 2)).to be true
      expect(rate_limiter.can_assign_to_agent?(agent, 3)).to be false
    end
  end

  describe '#get_agents_assignment_status' do
    let(:agent2) { create(:user, account: account) }
    let(:agents) { [agent, agent2] }

    before do
      2.times { rate_limiter.increment_agent_assignments(agent) }
      4.times { rate_limiter.increment_agent_assignments(agent2) }
    end

    it 'returns status for all agents' do
      status = rate_limiter.get_agents_assignment_status(agents)
      
      expect(status).to be_an(Array)
      expect(status.size).to eq(2)
      
      agent_status = status.find { |s| s[:agent] == agent }
      expect(agent_status).to include(
        agent: agent,
        current_assignments: 2,
        remaining_assignments: 3,
        within_limits: true
      )
      
      agent2_status = status.find { |s| s[:agent] == agent2 }
      expect(agent2_status).to include(
        agent: agent2,
        current_assignments: 4,
        remaining_assignments: 1,
        within_limits: true
      )
    end
  end

  describe '#reset_agent_limits' do
    before do
      3.times { rate_limiter.increment_agent_assignments(agent) }
    end

    it 'resets agent assignment count to 0' do
      expect { rate_limiter.reset_agent_limits(agent) }
        .to change { rate_limiter.get_agent_assignment_count(agent) }.from(3).to(0)
    end

    context 'when Redis fails' do
      before do
        allow(Redis::Alfred).to receive(:del).and_raise(Redis::ConnectionError)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and continues' do
        expect { rate_limiter.reset_agent_limits(agent) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Rate limiter reset failed/)
      end
    end
  end

  describe '#time_until_next_window' do
    it 'returns time until next window boundary' do
      # Mock current time to make test predictable
      travel_to(Time.zone.parse('2024-01-01 10:30:00')) do
        time_until = rate_limiter.time_until_next_window
        expect(time_until).to be > 0
        expect(time_until).to be <= 3600
      end
    end
  end

  describe 'window boundaries' do
    it 'resets count in new window' do
      # Set up assignment in current window
      2.times { rate_limiter.increment_agent_assignments(agent) }
      expect(rate_limiter.get_agent_assignment_count(agent)).to eq(2)
      
      # Travel to next window (advance by window size)
      travel(3601.seconds) do
        expect(rate_limiter.get_agent_assignment_count(agent)).to eq(0)
        expect(rate_limiter.agent_within_limits?(agent)).to be true
      end
    end
  end

  describe 'concurrent access' do
    it 'handles concurrent increments correctly' do
      threads = []
      results = []
      
      # Simulate concurrent assignment requests
      5.times do
        threads << Thread.new do
          results << rate_limiter.agent_within_limits?(agent)
          rate_limiter.increment_agent_assignments(agent) if results.last
        end
      end
      
      threads.each(&:join)
      
      # Final count should not exceed the limit
      final_count = rate_limiter.get_agent_assignment_count(agent)
      expect(final_count).to be <= 5
      expect(results.count(true)).to eq(final_count)
    end
  end
end