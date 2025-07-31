# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::RateLimiter, type: :service do
  before do
    # Mock GlobalConfig to avoid InstallationConfig issues
    allow(GlobalConfig).to receive(:get).and_return({})
    redis = Redis.new(Redis::Config.app)
    redis.flushdb if Rails.env.test?

    # Ensure inbox_assignment_policy exists so the inbox has a policy
    inbox_assignment_policy
  end

  let(:account) { create(:account) }
  let(:policy) { create(:assignment_policy, account: account, fair_distribution_limit: 5, fair_distribution_window: 3600) }
  let(:agent) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:inbox_assignment_policy) { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: policy) }
  let(:rate_limiter) { described_class.new(inbox: inbox, user: agent) }

  describe '#initialize' do
    it 'sets up rate limiter with inbox and user' do
      expect(rate_limiter.instance_variable_get(:@inbox)).to eq(inbox)
      expect(rate_limiter.instance_variable_get(:@user)).to eq(agent)
    end
  end

  describe '#within_limits?' do
    context 'when agent has no assignments in current window' do
      it 'returns true' do
        expect(rate_limiter.within_limits?).to be true
      end
    end

    context 'when agent is below limit' do
      before do
        # Simulate 3 assignments in current window
        3.times { rate_limiter.record_assignment(create(:conversation)) }
      end

      it 'returns true' do
        expect(rate_limiter.within_limits?).to be true
      end
    end

    context 'when agent reaches limit' do
      before do
        # Simulate reaching the limit (5 assignments)
        5.times { rate_limiter.record_assignment(create(:conversation)) }
      end

      it 'returns false' do
        expect(rate_limiter.within_limits?).to be false
      end
    end

    context 'when agent exceeds limit' do
      before do
        # Simulate exceeding the limit
        6.times { rate_limiter.record_assignment(create(:conversation)) }
      end

      it 'returns false' do
        expect(rate_limiter.within_limits?).to be false
      end
    end
  end

  describe '#record_assignment' do
    let(:conversation) { create(:conversation, inbox: inbox) }

    it 'increments assignment count for agent' do
      initial_status = rate_limiter.status
      rate_limiter.record_assignment(conversation)
      new_status = rate_limiter.status

      expect(new_status[:current_count]).to eq(initial_status[:current_count] + 1)
    end

    it 'sets expiration on the key' do
      rate_limiter.record_assignment(conversation)

      current_window = (Time.current.to_i / 3600) * 3600
      key = "assignment_v2:rate_limit:#{agent.id}:#{current_window}"

      redis = Redis.new(Redis::Config.app)
      ttl = redis.ttl(key)
      expect(ttl).to be > 0
      expect(ttl).to be <= 3600
    end

    context 'when Redis fails' do
      before do
        redis_double = instance_double(Redis)
        allow(Redis).to receive(:new).and_return(redis_double)
        allow(redis_double).to receive(:multi).and_raise(Redis::ConnectionError)
        allow(Rails.logger).to receive(:error)
      end

      it 'raises error' do
        expect { rate_limiter.record_assignment(conversation) }.to raise_error(Redis::ConnectionError)
      end
    end
  end

  describe '#status' do
    it 'returns correct status for agent with no assignments' do
      status = rate_limiter.status
      expect(status[:current_count]).to eq(0)
      expect(status[:within_limits]).to be true
      expect(status[:limit]).to eq(5)
    end

    it 'returns correct count after assignments' do
      3.times { rate_limiter.record_assignment(create(:conversation)) }
      status = rate_limiter.status
      expect(status[:current_count]).to eq(3)
      expect(status[:within_limits]).to be true
    end

    context 'when Redis fails' do
      before do
        redis_double = instance_double(Redis)
        allow(Redis).to receive(:new).and_return(redis_double)
        allow(redis_double).to receive(:get).and_raise(Redis::ConnectionError)
        allow(Rails.logger).to receive(:error)
      end

      it 'raises error' do
        expect { rate_limiter.status }.to raise_error(Redis::ConnectionError)
      end
    end
  end

  describe 'remaining assignments' do
    it 'returns full limit when no assignments made' do
      status = rate_limiter.status
      expect(status[:limit] - status[:current_count]).to eq(5)
    end

    it 'returns correct remaining count' do
      2.times { rate_limiter.record_assignment(create(:conversation)) }
      status = rate_limiter.status
      expect(status[:limit] - status[:current_count]).to eq(3)
    end

    it 'returns 0 when limit reached' do
      5.times { rate_limiter.record_assignment(create(:conversation)) }
      status = rate_limiter.status
      expect(status[:limit] - status[:current_count]).to eq(0)
    end

    it 'returns negative when limit exceeded' do
      6.times { rate_limiter.record_assignment(create(:conversation)) }
      status = rate_limiter.status
      expect(status[:limit] - status[:current_count]).to eq(-1)
    end
  end

  describe 'assignment capacity checks' do
    it 'returns true when agent has remaining capacity' do
      2.times { rate_limiter.record_assignment(create(:conversation)) }
      expect(rate_limiter.within_limits?).to be true
    end

    it 'returns false when agent has no capacity' do
      5.times { rate_limiter.record_assignment(create(:conversation)) }
      expect(rate_limiter.within_limits?).to be false
    end

    it 'correctly tracks multiple assignments' do
      3.times { rate_limiter.record_assignment(create(:conversation)) }

      status = rate_limiter.status
      expect(status[:current_count]).to eq(3)
      expect(status[:within_limits]).to be true
      expect(status[:limit] - status[:current_count]).to eq(2)
    end
  end

  describe 'multiple agents' do
    let(:agent2) { create(:user, account: account) }
    let(:rate_limiter2) { described_class.new(inbox: inbox, user: agent2) }

    before do
      2.times { rate_limiter.record_assignment(create(:conversation)) }
      4.times { rate_limiter2.record_assignment(create(:conversation)) }
    end

    it 'tracks status independently for each agent' do
      status1 = rate_limiter.status
      status2 = rate_limiter2.status

      expect(status1[:current_count]).to eq(2)
      expect(status1[:within_limits]).to be true
      expect(status1[:limit] - status1[:current_count]).to eq(3)

      expect(status2[:current_count]).to eq(4)
      expect(status2[:within_limits]).to be true
      expect(status2[:limit] - status2[:current_count]).to eq(1)
    end
  end

  describe 'reset functionality' do
    before do
      3.times { rate_limiter.record_assignment(create(:conversation)) }
    end

    it 'can be reset by clearing Redis key' do
      status_before = rate_limiter.status
      expect(status_before[:current_count]).to eq(3)

      # Manually clear the key
      redis = Redis.new(Redis::Config.app)
      current_window = (Time.current.to_i / 3600) * 3600
      key = "assignment_v2:rate_limit:#{agent.id}:#{current_window}"
      redis.del(key)

      status_after = rate_limiter.status
      expect(status_after[:current_count]).to eq(0)
    end

    context 'when Redis fails' do
      before do
        redis_double = instance_double(Redis)
        allow(Redis).to receive(:new).and_return(redis_double)
        allow(redis_double).to receive(:del).and_raise(Redis::ConnectionError)
        allow(Rails.logger).to receive(:error)
      end

      it 'raises error' do
        redis = Redis.new(Redis::Config.app)
        current_window = (Time.current.to_i / 3600) * 3600
        key = "assignment_v2:rate_limit:#{agent.id}:#{current_window}"
        expect { redis.del(key) }.to raise_error(Redis::ConnectionError)
      end
    end
  end

  describe 'window timing' do
    it 'calculates reset time correctly' do
      # Mock current time to make test predictable
      travel_to(Time.zone.parse('2024-01-01 10:30:00')) do
        status = rate_limiter.status
        reset_time = status[:reset_at]

        expect(reset_time).to be_a(Time)
        expect(reset_time).to be > Time.current
        expect(reset_time - Time.current).to be <= 3600
      end
    end
  end

  describe 'window boundaries' do
    it 'resets count in new window' do
      # Set up assignment in current window
      2.times { rate_limiter.record_assignment(create(:conversation)) }
      expect(rate_limiter.status[:current_count]).to eq(2)

      # Travel to next window (advance by window size)
      travel(3601.seconds) do
        expect(rate_limiter.status[:current_count]).to eq(0)
        expect(rate_limiter.within_limits?).to be true
      end
    end
  end

  describe 'concurrent access' do
    it 'handles concurrent increments correctly' do
      threads = []
      results = []
      mutex = Mutex.new

      # Simulate concurrent assignment requests
      5.times do
        threads << Thread.new do
          within_limits = rate_limiter.within_limits?
          mutex.synchronize { results << within_limits }
          rate_limiter.record_assignment(create(:conversation)) if within_limits
        end
      end

      threads.each(&:join)

      # Final count should not exceed the limit
      final_count = rate_limiter.status[:current_count]
      expect(final_count).to be <= 5
      expect(results.count(true)).to eq(final_count)
    end
  end
end
