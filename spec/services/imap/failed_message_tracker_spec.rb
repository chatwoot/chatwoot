require 'rails_helper'

RSpec.describe Imap::FailedMessageTracker do
  let(:inbox) { create(:inbox) }
  let(:tracker) { described_class.new(inbox: inbox) }
  let(:message_id) { 'message-id@example.com' }
  let(:redis_key) do
    format(Redis::RedisKeys::IMAP_FAILED_MESSAGE,
           inbox_id: inbox.id,
           message_id_digest: Digest::SHA256.hexdigest(message_id))
  end

  after do
    Redis::Alfred.delete(redis_key)
  end

  describe '#skip?' do
    it 'does not skip messages that never failed' do
      expect(tracker.skip?(message_id)).to be false
    end

    it 'skips a message that failed within the backoff window' do
      tracker.record_failure(message_id)

      expect(tracker.skip?(message_id)).to be true
    end

    it 'does not skip after the backoff has elapsed' do
      travel_to 6.minutes.ago do
        tracker.record_failure(message_id)
      end

      expect(tracker.skip?(message_id)).to be false
    end

    it 'backs off for longer after the second failure' do
      travel_to 21.minutes.ago do
        tracker.record_failure(message_id)
      end
      travel_to 6.minutes.ago do
        tracker.record_failure(message_id)
      end

      expect(tracker.skip?(message_id)).to be true
    end

    it 'skips the message once the failures are exhausted' do
      described_class::MAX_FAILURES.times { tracker.record_failure(message_id) }

      travel_to 1.hour.from_now do
        expect(tracker.skip?(message_id)).to be true
      end
    end
  end

  describe '#record_failure' do
    it 'increments the failure count' do
      expect(tracker.record_failure(message_id)).to eq 1
      expect(tracker.record_failure(message_id)).to eq 2
    end
  end
end
