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

      it 'appends to last conversation when if conversation already exisits' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa', 'text' => { 'body' => 'Test' },
                           'timestamp' => '1633034394', 'type' => 'text' }]
        }.with_indifferent_access

        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        2.times.each { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(3)
        # message appended to the last conversation
        expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
      end
    end

    context 'when unsupported message types' do
      it 'ignores type ephemeral' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa', 'text' => { 'body' => 'Test' },
                           'timestamp' => '1633034394', 'type' => 'ephemeral' }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.count).to eq(0)
      end

      it 'ignores type unsupported' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{
            'errors' => [{ 'code': 131_051, 'title': 'Message type is currently not supported.' }],
            'from': '2423423243', 'id': 'wamid.SDFADSf23sfasdafasdfa',
            'timestamp': '1667047370', 'type': 'unsupported'
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.count).to eq(0)
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
        expect(whatsapp_channel.inbox.messages.first.attachments.present?).to be true
      end
    end

    context 'when valid location message params' do
      it 'creates appropriate conversations, message and contacts' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa',
                           'location' => { 'id' => 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                                           'address': 'San Francisco, CA, USA',
                                           'latitude': 37.7893768,
                                           'longitude': -122.3895553,
                                           'name': 'Bay Bridge',
                                           'url': 'http://location_url.test' },
                           'timestamp' => '1633034394', 'type' => 'location' }]
        }.with_indifferent_access
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        location_attachment = whatsapp_channel.inbox.messages.first.attachments.first
        expect(location_attachment.file_type).to eq('location')
        expect(location_attachment.fallback_title).to eq('Bay Bridge, San Francisco, CA, USA')
        expect(location_attachment.coordinates_lat).to eq(37.7893768)
        expect(location_attachment.coordinates_long).to eq(-122.3895553)
        expect(location_attachment.external_url).to eq('http://location_url.test')
      end
    end
  end
end
