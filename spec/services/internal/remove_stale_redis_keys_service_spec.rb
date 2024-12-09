# spec/services/remove_stale_redis_keys_service_spec.rb
require 'rails_helper'

RSpec.describe Internal::RemoveStaleRedisKeysService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account_id: account.id) }
  let(:redis_key) { "online_presence:contacts:#{account.id}" }
  let(:presence_duration) { 20.seconds }

  describe '#perform' do
    before do
      # Mock OnlineStatusTracker methods
      allow(OnlineStatusTracker).to receive(:presence_key)
        .with(account.id, 'Contact')
        .and_return(redis_key)

      allow(OnlineStatusTracker).to receive_message_chain(:PRESENCE_DURATION)
        .and_return(presence_duration)
      
      allow(Rails.logger).to receive(:info)
    end

    it 'logs the cleanup operation' do
      expect(Rails.logger).to receive(:info)
        .with("Removing redis stale keys for account ##{account.id}")
      
      service.perform
    end

    it 'calls Redis::Alfred.zremrangebyscore with correct parameters' do
      current_time = Time.zone.now
      allow(Time.zone).to receive(:now).and_return(current_time)
      cutoff_time = (current_time - presence_duration).to_i

      expect(Redis::Alfred).to receive(:zremrangebyscore)
        .with(redis_key, '-inf', "(#{cutoff_time}")

      service.perform
    end

    context 'when Redis operation succeeds' do
      before do
        allow(Redis::Alfred).to receive(:zremrangebyscore).and_return(5)
      end

      it 'completes without error' do
        expect { service.perform }.not_to raise_error
      end
    end

    context 'when Redis operation fails' do
      before do
        allow(Redis::Alfred).to receive(:zremrangebyscore)
          .and_raise(Redis::CommandError.new("Redis connection error"))
      end

      it 'raises the error' do
        expect { service.perform }.to raise_error(Redis::CommandError)
      end
    end

  end
end
