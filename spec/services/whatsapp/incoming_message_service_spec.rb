require 'rails_helper'

describe Whatsapp::IncomingMessageService do
  let!(:whatsapp_channel) { create(:channel_whatsapp) }

  describe '#perform' do
    context 'when valid text message params' do
      it 'creates appropriate conversations, message and contacts' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa', 'text' => { 'body' => 'Test' },
                           'timestamp' => '1633034394', 'type' => 'text' }]
        }.with_indifferent_access
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Test')
      end
    end
  end
end
