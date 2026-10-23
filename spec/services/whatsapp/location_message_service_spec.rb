require 'rails_helper'

RSpec.describe Whatsapp::LocationMessageService do
  subject(:message) { described_class.new(conversation: conversation, sender: agent, params: params).perform }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:conversation) { create(:conversation, account: inbox.account, inbox: inbox) }
  let(:agent) { create(:user, account: inbox.account, role: :agent) }
  let(:saved_location) do
    { 'id' => 'loc-1', 'name' => 'Main Store', 'address' => '1 Main St', 'latitude' => 4.711, 'longitude' => -74.072 }
  end

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    whatsapp_channel.update!(locations: [saved_location])
  end

  context 'with a saved location' do
    let(:params) { { location_id: 'loc-1' } }

    it 'stores the location saved on the channel' do
      expect(message).to be_outgoing
      expect(message.content).to eq("Main Store\n1 Main St")
      expect(message.content_attributes['whatsapp_location']).to eq(saved_location)
    end
  end

  context 'with the current location' do
    let(:params) { { latitude: '4.5', longitude: '-74.1' } }

    it 'stores only the coordinates' do
      expect(message.content).to eq("Current location\n4.5, -74.1")
      expect(message.content_attributes['whatsapp_location']).to eq('latitude' => 4.5, 'longitude' => -74.1)
    end
  end

  context 'with an unknown location id' do
    let(:params) { { location_id: 'missing' } }

    it 'raises an error' do
      expect { message }.to raise_error(described_class::Error, 'Location not found')
    end
  end

  context 'with out of range coordinates' do
    let(:params) { { latitude: '91', longitude: '10' } }

    it 'raises an error' do
      expect { message }.to raise_error(described_class::Error, /latitude must be between/)
    end
  end

  context 'with both a location id and coordinates' do
    let(:params) { { location_id: 'loc-1', latitude: '4.5', longitude: '-74.1' } }

    it 'raises an error' do
      expect { message }.to raise_error(described_class::Error, /not both/)
    end
  end
end
