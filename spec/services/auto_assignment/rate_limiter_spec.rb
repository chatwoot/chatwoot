require 'rails_helper'

RSpec.describe AutoAssignment::RateLimiter do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, inbox: inbox) }
  let(:rate_limiter) { described_class.new(inbox: inbox, agent: agent) }
  let(:assignment_key) { format(Redis::RedisKeys::ASSIGNMENT_KEY, inbox_id: inbox.id, agent_id: agent.id) }

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
        rate_limiter.track_assignment(conversation)

        expect(Redis::Alfred.ttl(assignment_key)).to eq(5.minutes.to_i)
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

      it 'records the assignment time and the configured expiry' do
        freeze_time do
          rate_limiter.track_assignment(conversation)

          expect(Redis::Alfred.zscore(assignment_key, conversation.id)).to eq(Time.now.to_i)
          expect(Redis::Alfred.ttl(assignment_key)).to eq(3600)
        end
      end

      it 'drops assignments that fell out of the window' do
        travel_to(70.minutes.ago) { rate_limiter.track_assignment(create(:conversation, inbox: inbox)) }
        travel_to(50.minutes.ago) { rate_limiter.track_assignment(create(:conversation, inbox: inbox)) }
        rate_limiter.track_assignment(conversation)

        expect(Redis::Alfred.zcard(assignment_key)).to eq(2)
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

      it 'counts only assignments made within the window' do
        travel_to(70.minutes.ago) { rate_limiter.track_assignment(create(:conversation, inbox: inbox)) }
        travel_to(50.minutes.ago) { rate_limiter.track_assignment(create(:conversation, inbox: inbox)) }

        expect(rate_limiter.current_count).to eq(1)
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
        rate_limiter.track_assignment(conversation)

        expect(Redis::Alfred.ttl(assignment_key)).to eq(7200)
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

      it 'uses the default window value of 5 minutes' do
        rate_limiter.track_assignment(conversation)

        expect(Redis::Alfred.ttl(assignment_key)).to eq(5.minutes.to_i)
      end
    end
  end
end
