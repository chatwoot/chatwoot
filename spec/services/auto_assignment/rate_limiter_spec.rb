require 'rails_helper'

RSpec.describe AutoAssignment::RateLimiter do
  # Stub Math methods for testing when assignment_policy is nil
  # rubocop:disable RSpec/BeforeAfterAll, RSpec/InstanceVariable
  before(:all) do
    @math_had_positive = Math.respond_to?(:positive?)
    Math.define_singleton_method(:positive?) { false } unless @math_had_positive
  end

  after(:all) do
    Math.singleton_class.send(:remove_method, :positive?) unless @math_had_positive
  end
  # rubocop:enable RSpec/BeforeAfterAll, RSpec/InstanceVariable

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, inbox: inbox) }
  let(:rate_limiter) { described_class.new(inbox: inbox, agent: agent) }

  describe '#within_limit?' do
    context 'when rate limiting is not enabled' do
      before do
        allow(inbox).to receive(:assignment_policy).and_return(nil)
      end

      it 'returns true' do
        expect(rate_limiter.within_limit?).to be true
      end
    end

    context 'when rate limiting is enabled' do
      let(:assignment_policy) do
        instance_double(AssignmentPolicy,
                        fair_distribution_limit: 5,
                        fair_distribution_window: 3600)
      end

      before do
        allow(inbox).to receive(:assignment_policy).and_return(assignment_policy)
      end

      it 'returns true when under the limit' do
        allow(rate_limiter).to receive(:current_count).and_return(3)
        expect(rate_limiter.within_limit?).to be true
      end

      it 'returns false when at or over the limit' do
        allow(rate_limiter).to receive(:current_count).and_return(5)
        expect(rate_limiter.within_limit?).to be false
      end
    end
  end

  describe '#track_assignment' do
    context 'when rate limiting is not enabled' do
      before do
        allow(inbox).to receive(:assignment_policy).and_return(nil)
      end

      it 'still tracks the assignment with default window' do
        expected_key = format(Redis::RedisKeys::ASSIGNMENT_KEY, inbox_id: inbox.id, agent_id: agent.id, conversation_id: conversation.id)
        expect(Redis::Alfred).to receive(:set).with(expected_key, conversation.id.to_s, ex: 24.hours.to_i)
        rate_limiter.track_assignment(conversation)
      end
    end

    context 'when rate limiting is enabled' do
      let(:assignment_policy) do
        instance_double(AssignmentPolicy,
                        fair_distribution_limit: 5,
                        fair_distribution_window: 3600)
      end

      before do
        allow(inbox).to receive(:assignment_policy).and_return(assignment_policy)
      end

      it 'creates a Redis key with correct expiry' do
        expected_key = format(Redis::RedisKeys::ASSIGNMENT_KEY, inbox_id: inbox.id, agent_id: agent.id, conversation_id: conversation.id)
        expect(Redis::Alfred).to receive(:set).with(
          expected_key,
          conversation.id.to_s,
          ex: 3600
        )
        rate_limiter.track_assignment(conversation)
      end
    end
  end

  describe '#current_count' do
    context 'when rate limiting is not enabled' do
      before do
        allow(inbox).to receive(:assignment_policy).and_return(nil)
      end

      it 'returns 0' do
        expect(rate_limiter.current_count).to eq(0)
      end
    end

    context 'when rate limiting is enabled' do
      let(:assignment_policy) do
        instance_double(AssignmentPolicy,
                        fair_distribution_limit: 5,
                        fair_distribution_window: 3600)
      end

      before do
        allow(inbox).to receive(:assignment_policy).and_return(assignment_policy)
      end

      it 'counts matching Redis keys' do
        pattern = format(Redis::RedisKeys::ASSIGNMENT_KEY_PATTERN, inbox_id: inbox.id, agent_id: agent.id)
        allow(Redis::Alfred).to receive(:keys_count).with(pattern).and_return(3)

        expect(rate_limiter.current_count).to eq(3)
      end
    end
  end

  describe 'configuration' do
    context 'with custom window' do
      let(:assignment_policy) do
        instance_double(AssignmentPolicy,
                        fair_distribution_limit: 10,
                        fair_distribution_window: 7200)
      end

      before do
        allow(inbox).to receive(:assignment_policy).and_return(assignment_policy)
      end

      it 'uses the custom window value' do
        expected_key = format(Redis::RedisKeys::ASSIGNMENT_KEY, inbox_id: inbox.id, agent_id: agent.id, conversation_id: conversation.id)
        expect(Redis::Alfred).to receive(:set).with(
          expected_key,
          conversation.id.to_s,
          ex: 7200
        )
        rate_limiter.track_assignment(conversation)
      end
    end

    context 'without custom window' do
      let(:assignment_policy) do
        instance_double(AssignmentPolicy,
                        fair_distribution_limit: 10,
                        fair_distribution_window: nil)
      end

      before do
        allow(inbox).to receive(:assignment_policy).and_return(assignment_policy)
      end

      it 'uses the default window value of 24 hours' do
        expected_key = format(Redis::RedisKeys::ASSIGNMENT_KEY, inbox_id: inbox.id, agent_id: agent.id, conversation_id: conversation.id)
        expect(Redis::Alfred).to receive(:set).with(
          expected_key,
          conversation.id.to_s,
          ex: 86_400
        )
        rate_limiter.track_assignment(conversation)
      end
    end
  end
end
