require 'rails_helper'

RSpec.describe Internal::RemoveStaleRedisKeysService, type: :service do
  let(:account_id) { 1 }
  let(:service) { described_class.new(account_id: account_id) }

  describe '#perform' do
    it 'removes stale Redis keys for the specified account' do
      presence_key = OnlineStatusTracker.presence_key(account_id, 'Contact')

      # Mock Redis calls
      expect(Redis::Alfred).to receive(:zremrangebyscore)
        .with(presence_key, '-inf', anything)

      service.perform
    end
  end
end
