require 'rails_helper'

RSpec.describe AutoAssignment::RateLimiter do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, inbox: inbox) }
  let(:rate_limiter) { described_class.new(inbox: inbox, agent: agent) }

  describe '#within_limit?' do
    context 'when rate limiting is not enabled' do
      before do
        allow(inbox).to receive(:auto_assignment_config).and_return({})
      end

      it 'returns true' do
        expect(rate_limiter.within_limit?).to be true
      end
    end

    context 'when rate limiting is enabled' do
      before do
        allow(inbox).to receive(:auto_assignment_config).and_return({
                                                                      'fair_distribution_limit' => 5,
                                                                      'fair_distribution_window' => 3600
                                                                    })
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
        allow(inbox).to receive(:auto_assignment_config).and_return({})
      end

      it 'does not track the assignment' do
        expect(Redis::Alfred).not_to receive(:set)
        rate_limiter.track_assignment(conversation)
      end
    end

    context 'when rate limiting is enabled' do
      before do
        allow(inbox).to receive(:auto_assignment_config).and_return({
                                                                      'fair_distribution_limit' => 5,
                                                                      'fair_distribution_window' => 3600
                                                                    })
      end

      it 'creates a Redis key with correct expiry' do
        expected_key = "assignment:#{inbox.id}:agent:#{agent.id}:conversation:#{conversation.id}"
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
        allow(inbox).to receive(:auto_assignment_config).and_return({})
      end

      it 'returns 0' do
        expect(rate_limiter.current_count).to eq(0)
      end
    end

    context 'when rate limiting is enabled' do
      before do
        allow(inbox).to receive(:auto_assignment_config).and_return({
                                                                      'fair_distribution_limit' => 5,
                                                                      'fair_distribution_window' => 3600
                                                                    })
      end

      it 'counts matching Redis keys' do
        pattern = "assignment:#{inbox.id}:agent:#{agent.id}:*"
        allow(Redis::Alfred).to receive(:keys_count).with(pattern).and_return(3)

        expect(rate_limiter.current_count).to eq(3)
      end
    end
  end

  describe 'configuration' do
    context 'with custom window' do
      before do
        allow(inbox).to receive(:auto_assignment_config).and_return({
                                                                      'fair_distribution_limit' => 10,
                                                                      'fair_distribution_window' => 7200
                                                                    })
      end

      it 'uses the custom window value' do
        expected_key = "assignment:#{inbox.id}:agent:#{agent.id}:conversation:#{conversation.id}"
        expect(Redis::Alfred).to receive(:set).with(
          expected_key,
          conversation.id.to_s,
          ex: 7200
        )
        rate_limiter.track_assignment(conversation)
      end
    end

    context 'without custom window' do
      before do
        allow(inbox).to receive(:auto_assignment_config).and_return({
                                                                      'fair_distribution_limit' => 10
                                                                    })
      end

      it 'uses the default window value of 3600' do
        expected_key = "assignment:#{inbox.id}:agent:#{agent.id}:conversation:#{conversation.id}"
        expect(Redis::Alfred).to receive(:set).with(
          expected_key,
          conversation.id.to_s,
          ex: 3600
        )
        rate_limiter.track_assignment(conversation)
      end
    end
  end
end
