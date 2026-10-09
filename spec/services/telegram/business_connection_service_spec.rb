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
          'last_update_id' => 200,
          'last_update_id_received_at' => Time.current.to_i,
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

      update_id_received_at = channel.business_config['last_update_id_received_at']
      travel_to(1.day.from_now) do
        service.observe_update(201)
        expect(channel.reload.business_config['last_update_id_received_at']).to eq(update_id_received_at)
      end

      service.observe_update(250)
      service.process({ id: 'connection-1', is_enabled: true }, update_id: 202)
      expect(channel.reload.business_config.dig('connections', 'connection-1')).to include('is_enabled' => true, 'update_id' => 202)

      travel_to(1.week.from_now) do
        service.observe_update(300)
        service.process({ id: 'connection-1', is_enabled: true }, update_id: 50)
        expect(channel.reload.business_config.dig('connections', 'connection-1')).to include('is_enabled' => true, 'update_id' => 202)
      end

      travel_to(2.weeks.from_now) do
        service.process({ id: 'connection-1', is_enabled: true }, update_id: 50)
        expect(channel.reload.business_config.dig('connections', 'connection-1')).to include('is_enabled' => true, 'update_id' => 50)
      end
    end

    it 'preserves the lifecycle update ID when a connection lookup refreshes state' do
      channel = create(
        :channel_telegram,
        business_config: {
          'can_connect_to_business' => true,
          'last_update_id' => 200,
          'last_update_id_received_at' => Time.current.to_i,
          'connections' => {
            'connection-1' => { 'id' => 'connection-1', 'is_enabled' => false, 'update_id' => 200 }
          }
        }
      )
      stub_request(:get, "#{channel.telegram_api_url}/getBusinessConnection")
        .with(query: { business_connection_id: 'connection-1' })
        .to_return(
          status: 200,
          body: { ok: true, result: { id: 'connection-1', is_enabled: true } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      service = described_class.new(channel: channel)

      service.sync('connection-1')
      expect(channel.reload.business_config.dig('connections', 'connection-1')).to include('is_enabled' => true, 'update_id' => 200)

      service.process({ id: 'connection-1', is_enabled: false }, update_id: 199)
      expect(channel.reload.business_config.dig('connections', 'connection-1')).to include('is_enabled' => true, 'update_id' => 200)
    end

    it 'does not apply a connection update after the channel bot token changes' do
      channel = create(:channel_telegram, business_config: { 'can_connect_to_business' => true, 'connections' => {} })
      service = described_class.new(channel: channel)
      # Simulate the channel record changing after the webhook job resolved the old token.
      # rubocop:disable Rails/SkipsModelValidations
      Channel::Telegram.find(channel.id).update_columns(
        bot_token: 'replacement-token',
        business_config: {
          'can_connect_to_business' => true,
          'connections' => { 'replacement-connection' => { 'id' => 'replacement-connection', 'is_enabled' => true } }
        }
      )
      # rubocop:enable Rails/SkipsModelValidations

      service.process({ id: 'old-bot-connection', is_enabled: true }, update_id: 200)
      service.observe_update(200)

      expect(channel.reload.business_config['connections'].keys).to contain_exactly('replacement-connection')
      expect(channel.business_config['last_update_id']).to be_nil
    end

    it 'does not apply a lookup response after a newer lifecycle update is stored' do
      channel = create(
        :channel_telegram,
        business_config: {
          'can_connect_to_business' => true,
          'connections' => {
            'connection-1' => { 'id' => 'connection-1', 'is_enabled' => false, 'update_id' => 200 }
          }
        }
      )
      service = described_class.new(channel: channel)
      stub_request(:get, "#{channel.telegram_api_url}/getBusinessConnection")
        .with(query: { business_connection_id: 'connection-1' })
        .to_return do
          current_channel = Channel::Telegram.find(channel.id)
          described_class.new(channel: current_channel).process({ id: 'connection-1', is_enabled: true }, update_id: 201)
          {
            status: 200,
            body: { ok: true, result: { id: 'connection-1', is_enabled: false } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          }
        end

      service.sync('connection-1')

      expect(channel.reload.business_config.dig('connections', 'connection-1')).to include('is_enabled' => true, 'update_id' => 201)
    end
  end
end
