require 'rails_helper'

describe Whatsapp::ConnectionAttemptTracker do
  let(:account_id) { 1 }
  let(:waba_id) { 'test_waba_id' }
  let(:tracker) { described_class.new(account_id, waba_id) }

  before do
    # Clear Redis keys before each test
    Redis::Alfred.del("whatsapp:connection_attempts:#{account_id}:#{waba_id}")
    Redis::Alfred.del("whatsapp:connection_failures:#{account_id}:#{waba_id}")
  end

  describe '#can_attempt?' do
    context 'when under the limit' do
      it 'returns true' do
        expect(tracker.can_attempt?).to be true
      end
    end

    context 'when at the limit' do
      before do
        described_class::MAX_ATTEMPTS.times { tracker.record_attempt!(success: false) }
      end

      it 'returns false' do
        expect(tracker.can_attempt?).to be false
      end
    end

    context 'when in cooldown' do
      before do
        # Record 3 failures to trigger cooldown
        3.times { tracker.record_attempt!(success: false) }
      end

      it 'returns false' do
        expect(tracker.can_attempt?).to be false
      end
    end
  end

  describe '#record_attempt!' do
    context 'when successful' do
      before do
        # First record some failures
        2.times { tracker.record_attempt!(success: false) }
      end

      it 'increments the attempt count' do
        expect { tracker.record_attempt!(success: true) }.to change { tracker.current_attempts }.by(1)
      end

      it 'clears the failure count' do
        tracker.record_attempt!(success: true)
        expect(tracker.consecutive_failures).to eq(0)
      end
    end

    context 'when failed' do
      it 'increments the attempt count' do
        expect { tracker.record_attempt!(success: false) }.to change { tracker.current_attempts }.by(1)
      end

      it 'increments the failure count' do
        expect { tracker.record_attempt!(success: false) }.to change { tracker.consecutive_failures }.by(1)
      end
    end
  end

  describe '#current_attempts' do
    it 'returns 0 when no attempts have been made' do
      expect(tracker.current_attempts).to eq(0)
    end

    it 'returns the correct count after attempts' do
      3.times { tracker.record_attempt!(success: false) }
      expect(tracker.current_attempts).to eq(3)
    end
  end

  describe '#attempts_remaining' do
    it 'returns MAX_ATTEMPTS when no attempts have been made' do
      expect(tracker.attempts_remaining).to eq(described_class::MAX_ATTEMPTS)
    end

    it 'returns the correct remaining count' do
      2.times { tracker.record_attempt!(success: false) }
      expect(tracker.attempts_remaining).to eq(described_class::MAX_ATTEMPTS - 2)
    end

    it 'returns 0 when at the limit' do
      described_class::MAX_ATTEMPTS.times { tracker.record_attempt!(success: false) }
      expect(tracker.attempts_remaining).to eq(0)
    end
  end

  describe '#time_until_reset' do
    it 'returns 0 when no attempts have been made' do
      expect(tracker.time_until_reset).to eq(0)
    end

    it 'returns a positive value after an attempt' do
      tracker.record_attempt!(success: false)
      expect(tracker.time_until_reset).to be > 0
    end
  end

  describe '#in_cooldown?' do
    context 'when fewer than 3 failures' do
      before do
        2.times { tracker.record_attempt!(success: false) }
      end

      it 'returns false' do
        expect(tracker.in_cooldown?).to be false
      end
    end

    context 'when 3 or more failures' do
      before do
        3.times { tracker.record_attempt!(success: false) }
      end

      it 'returns true' do
        expect(tracker.in_cooldown?).to be true
      end
    end
  end

  describe '#cooldown_remaining' do
    context 'when not in cooldown' do
      it 'returns 0' do
        expect(tracker.cooldown_remaining).to eq(0)
      end
    end

    context 'when in cooldown' do
      before do
        3.times { tracker.record_attempt!(success: false) }
      end

      it 'returns a positive value' do
        expect(tracker.cooldown_remaining).to be > 0
      end
    end
  end

  describe '#consecutive_failures' do
    it 'returns 0 when no failures' do
      expect(tracker.consecutive_failures).to eq(0)
    end

    it 'returns the correct failure count' do
      3.times { tracker.record_attempt!(success: false) }
      expect(tracker.consecutive_failures).to eq(3)
    end

    it 'resets to 0 after a successful attempt' do
      2.times { tracker.record_attempt!(success: false) }
      tracker.record_attempt!(success: true)
      expect(tracker.consecutive_failures).to eq(0)
    end
  end

  describe '#status' do
    it 'returns the correct status hash' do
      status = tracker.status

      expect(status).to include(
        can_attempt: true,
        attempts_remaining: described_class::MAX_ATTEMPTS,
        time_until_reset: 0,
        in_cooldown: false,
        cooldown_remaining: 0
      )
    end

    context 'after multiple failures' do
      before do
        3.times { tracker.record_attempt!(success: false) }
      end

      it 'reflects the correct state' do
        status = tracker.status

        expect(status[:can_attempt]).to be false
        expect(status[:attempts_remaining]).to eq(described_class::MAX_ATTEMPTS - 3)
        expect(status[:in_cooldown]).to be true
        expect(status[:cooldown_remaining]).to be > 0
      end
    end
  end

  describe 'cooldown calculation' do
    it 'increases cooldown exponentially with failures' do
      # First failure - 5 minutes
      tracker.record_attempt!(success: false)
      first_cooldown = Redis::Alfred.ttl("whatsapp:connection_failures:#{account_id}:#{waba_id}")

      # Clear and try again
      Redis::Alfred.del("whatsapp:connection_failures:#{account_id}:#{waba_id}")

      # Two failures - 10 minutes
      2.times { tracker.record_attempt!(success: false) }
      second_cooldown = Redis::Alfred.ttl("whatsapp:connection_failures:#{account_id}:#{waba_id}")

      expect(second_cooldown).to be > first_cooldown
    end

    it 'caps cooldown at 1 hour' do
      # Many failures should still cap at 1 hour
      10.times { tracker.record_attempt!(success: false) }
      cooldown = Redis::Alfred.ttl("whatsapp:connection_failures:#{account_id}:#{waba_id}")

      expect(cooldown).to be <= 1.hour.to_i
    end
  end
end
