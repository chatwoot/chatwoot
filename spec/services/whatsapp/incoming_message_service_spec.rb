require 'rails_helper'

describe Whatsapp::IncomingMessageService do
  describe '#perform' do
    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
    end

    let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false) }

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

    context 'when valid interactive message params' do
      it 'creates appropriate conversations, message and contacts' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa',
                           'interactive': {
                             'button_reply': {
                               'id': '1',
                               'title': 'First Button'
                             },
                             'type': 'button_reply'
                           },
                           'timestamp' => '1633034394', 'type' => 'interactive' }]
        }.with_indifferent_access
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('First Button')
      end
    end

    # ref: https://github.com/chatwoot/chatwoot/issues/3795#issuecomment-1018057318
    context 'when valid template button message params' do
      it 'creates appropriate conversations, message and contacts' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa',
                           'button' => {
                             'text' => 'Yes this is a button'
                           },
                           'timestamp' => '1633034394', 'type' => 'button' }]
        }.with_indifferent_access
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Yes this is a button')
      end
    end

    context 'when valid attachment message params' do
      it 'creates appropriate conversations, message and contacts' do
        stub_request(:get, whatsapp_channel.media_url('b1c68f38-8734-4ad3-b4a1-ef0c10d683')).to_return(
          status: 200,
          body: File.read('spec/assets/sample.png'),
          headers: {}
        )
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa',
                           'image' => { 'id' => 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                                        'mime_type' => 'image/jpeg',
                                        'sha256' => '29ed500fa64eb55fc19dc4124acb300e5dcca0f822a301ae99944db',
                                        'caption' => 'Check out my product!' },
                           'timestamp' => '1633034394', 'type' => 'image' }]
        }.with_indifferent_access
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Check out my product!')
        expect(whatsapp_channel.inbox.messages.first.attachments.present?).to eq true
      end
    end
  end
end
