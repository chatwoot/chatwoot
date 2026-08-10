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

      described_class.new(channel: channel).process(id: 'new-connection', is_enabled: true)

      expect(channel).to have_received(:with_lock)
      expect(channel.reload.business_config['connections'].keys).to contain_exactly('existing-connection', 'new-connection')
    end
  end
end
