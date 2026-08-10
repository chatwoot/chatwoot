require 'rails_helper'

RSpec.describe Telegram::BusinessConnectionService do
  describe '#process' do
    it 'locks the channel while merging a connection into the latest provider state' do
      channel = create(
        :channel_telegram,
        business_config: {
          'can_connect_to_business' => true,
          'connections' => { 'existing-connection' => { 'id' => 'existing-connection', 'is_enabled' => false } }
        }
      )
      allow(channel).to receive(:with_lock).and_yield

      described_class.new(channel: channel).process({ id: 'new-connection', is_enabled: true })

      expect(channel).to have_received(:with_lock)
      expect(channel.reload.business_config['connections'].keys).to contain_exactly('existing-connection', 'new-connection')
    end

    it 'does not let an older lifecycle update overwrite a newer update for the same connection' do
      channel = create(
        :channel_telegram,
        business_config: {
          'can_connect_to_business' => true,
          'connections' => {
            'connection-1' => { 'id' => 'connection-1', 'is_enabled' => true, 'update_id' => 200 }
          }
        }
      )
      service = described_class.new(channel: channel)

      service.process({ id: 'connection-1', is_enabled: false }, update_id: 199)
      expect(channel.reload.business_config.dig('connections', 'connection-1')).to include('is_enabled' => true, 'update_id' => 200)

      service.process({ id: 'connection-1', is_enabled: false }, update_id: 201)
      expect(channel.reload.business_config.dig('connections', 'connection-1')).to include('is_enabled' => false, 'update_id' => 201)
    end
  end
end
