require 'rails_helper'

describe Whatsapp::IncomingMessageService do
  describe '#perform' do
    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
    end

    let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false) }
    let(:wa_id) { '2423423243' }
    let!(:params) do
      {
        'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => wa_id }],
        'messages' => [{ 'from' => wa_id, 'id' => 'SDFADSf23sfasdafasdfa', 'text' => { 'body' => 'Test' },
                         'timestamp' => '1633034394', 'type' => 'text' }]
      }.with_indifferent_access
    end

    context 'when valid text message params' do
      it 'creates appropriate conversations, message and contacts' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Test')
      end

      it 'appends to last conversation when if conversation already exists' do
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        2.times.each { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(3)
        # message appended to the last conversation
        expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
      end

      it 'reopen last conversation if last conversation is resolved and lock to single conversation is enabled' do
        whatsapp_channel.inbox.update!(lock_to_single_conversation: true)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
        last_conversation.update!(status: 'resolved')
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        # message appended to the last conversation
        expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
        expect(last_conversation.reload.status).to eq('open')
      end

      it 'creates a new conversation if last conversation is resolved and lock to single conversation is disabled' do
        whatsapp_channel.inbox.update!(lock_to_single_conversation: false)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
        last_conversation.update!(status: 'resolved')
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(2)
        expect(contact_inbox.conversations.last.messages.last.content).to eq(params[:messages].first[:text][:body])
      end

      it 'will not create a new conversation if last conversation is not resolved and lock to single conversation is disabled' do
        whatsapp_channel.inbox.update!(lock_to_single_conversation: false)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
        last_conversation.update!(status: Conversation.statuses.except('resolved').keys.sample)
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(contact_inbox.conversations.last.messages.last.content).to eq(params[:messages].first[:text][:body])
      end

      it 'will not create duplicate messages when same message is received' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.messages.count).to eq(1)

        # this shouldn't create a duplicate message
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.messages.count).to eq(1)
      end
    end

    context 'when unsupported message types' do
      it 'ignores type ephemeral and does not create ghost conversation' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa', 'text' => { 'body' => 'Test' },
                           'timestamp' => '1633034394', 'type' => 'ephemeral' }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(0)
        expect(Contact.count).to eq(0)
        expect(whatsapp_channel.inbox.messages.count).to eq(0)
      end

      it 'ignores type unsupported and does not create ghost conversation' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{
            'errors' => [{ 'code': 131_051, 'title': 'Message type is currently not supported.' }],
            :from => '2423423243', :id => 'wamid.SDFADSf23sfasdafasdfa',
            :timestamp => '1667047370', :type => 'unsupported'
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(0)
        expect(Contact.count).to eq(0)
        expect(whatsapp_channel.inbox.messages.count).to eq(0)
      end
    end

    context 'when valid status params' do
      let(:from) { '2423423243' }
      let(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: from) }
      let(:params) do
        {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => from }],
          'messages' => [{ 'from' => from, 'id' => from, 'text' => { 'body' => 'Test' },
                           'timestamp' => '1633034394', 'type' => 'text' }]
        }.with_indifferent_access
      end

      before do
        create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
      end

      it 'update status message to read' do
        status_params = {
          'statuses' => [{ 'recipient_id' => from, 'id' => from, 'status' => 'read' }]
        }.with_indifferent_access
        message = Message.find_by!(source_id: from)
        expect(message.status).to eq('sent')
        described_class.new(inbox: whatsapp_channel.inbox, params: status_params).perform
        expect(message.reload.status).to eq('read')
      end

      it 'update status message to failed' do
        status_params = {
          'statuses' => [{ 'recipient_id' => from, 'id' => from, 'status' => 'failed',
                           'errors' => [{ 'code': 123, 'title': 'abc' }] }]
        }.with_indifferent_access

        message = Message.find_by!(source_id: from)
        expect(message.status).to eq('sent')
        described_class.new(inbox: whatsapp_channel.inbox, params: status_params).perform
        expect(message.reload.status).to eq('failed')
        expect(message.external_error).to eq('123: abc')
      end

      it 'will not throw error if unsupported status' do
        status_params = {
          'statuses' => [{ 'recipient_id' => from, 'id' => from, 'status' => 'deleted',
                           'errors' => [{ 'code': 123, 'title': 'abc' }] }]
        }.with_indifferent_access

        message = Message.find_by!(source_id: from)
        expect(message.status).to eq('sent')
        expect { described_class.new(inbox: whatsapp_channel.inbox, params: status_params).perform }.not_to raise_error
      end
    end

    context 'when valid interactive message params' do
      it 'creates appropriate conversations, message and contacts' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa',
                           :interactive => {
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
                                           :address => 'San Francisco, CA, USA',
                                           :latitude => 37.7893768,
                                           :longitude => -122.3895553,
                                           :name => 'Bay Bridge',
                                           :url => 'http://location_url.test' },
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

    context 'when valid contact message params' do
      it 'creates appropriate message and attachments' do
        params = { 'contacts' => [{ 'profile' => { 'name' => 'Kedar' }, 'wa_id' => '919746334593' }],
                   'messages' => [{ 'from' => '919446284490',
                                    'id' => 'wamid.SDFADSf23sfasdafasdfa',
                                    'timestamp' => '1675823265',
                                    'type' => 'contacts',
                                    'contacts' => [
                                      {
                                        'name' => { 'formatted_name' => 'Apple Inc.' },
                                        'phones' => [{ 'phone' => '+911800', 'type' => 'MAIN' }]
                                      },
                                      { 'name' => { 'first_name' => 'Chatwoot', 'formatted_name' => 'Chatwoot' },
                                        'phones' => [{ 'phone' => '+1 (415) 341-8386' }] }
                                    ] }] }.with_indifferent_access
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(Contact.all.first.name).to eq('Kedar')

        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)

        # Two messages are tested deliberately to ensure multiple contact attachments work.
        m1 = whatsapp_channel.inbox.messages.first
        contact_attachments = m1.attachments.first
        expect(m1.content).to eq('Apple Inc.')
        expect(contact_attachments.fallback_title).to eq('+911800')

        m2 = whatsapp_channel.inbox.messages.last
        contact_attachments = m2.attachments.first
        expect(m2.content).to eq('Chatwoot')
        expect(contact_attachments.fallback_title).to eq('+1 (415) 341-8386')
      end
    end

    # ref: https://github.com/chatwoot/chatwoot/issues/5840
    describe 'When the incoming waid is a brazilian number in new format with 9 included' do
      let(:wa_id) { '5541988887777' }

      it 'creates appropriate conversations, message and contacts if contact does not exit' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Test')
        expect(whatsapp_channel.inbox.contact_inboxes.first.source_id).to eq(wa_id)
      end

      it 'appends to existing contact if contact inbox exists' do
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: wa_id)
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        # message appended to the last conversation
        expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
      end
    end

    describe 'When incoming waid is a brazilian number in old format without the 9 included' do
      let(:wa_id) { '554188887777' }

      context 'when a contact inbox exists in the old format without 9 included' do
        it 'appends to existing contact' do
          contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: wa_id)
          last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
          described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
          # no new conversation should be created
          expect(whatsapp_channel.inbox.conversations.count).to eq(1)
          # message appended to the last conversation
          expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
        end
      end

      context 'when a contact inbox exists in the new format with 9 included' do
        it 'appends to existing contact' do
          contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '5541988887777')
          last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
          described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
          # no new conversation should be created
          expect(whatsapp_channel.inbox.conversations.count).to eq(1)
          # message appended to the last conversation
          expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
        end
      end

      context 'when a contact inbox does not exist in the new format with 9 included' do
        it 'creates contact inbox with the incoming waid' do
          described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
          expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
          expect(Contact.all.first.name).to eq('Sojan Jose')
          expect(whatsapp_channel.inbox.messages.first.content).to eq('Test')
          expect(whatsapp_channel.inbox.contact_inboxes.first.source_id).to eq(wa_id)
        end
      end
    end

    describe 'when message processing is in progress' do
      it 'ignores the current message creation request' do
        params = { 'contacts' => [{ 'profile' => { 'name' => 'Kedar' }, 'wa_id' => '919746334593' }],
                   'messages' => [{ 'from' => '919446284490',
                                    'id' => 'wamid.SDFADSf23sfasdafasdfa',
                                    'timestamp' => '1675823265',
                                    'type' => 'contacts',
                                    'contacts' => [
                                      {
                                        'name' => { 'formatted_name' => 'Apple Inc.' },
                                        'phones' => [{ 'phone' => '+911800', 'type' => 'MAIN' }]
                                      },
                                      { 'name' => { 'first_name' => 'Chatwoot', 'formatted_name' => 'Chatwoot' },
                                        'phones' => [{ 'phone' => '+1 (415) 341-8386' }] }
                                    ] }] }.with_indifferent_access

        expect(Message.find_by(source_id: 'wamid.SDFADSf23sfasdafasdfa')).not_to be_present
        key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: 'wamid.SDFADSf23sfasdafasdfa')

        Redis::Alfred.setex(key, true)
        expect(Redis::Alfred.get(key)).to be_truthy

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.messages.count).to eq(0)
        expect(Message.find_by(source_id: 'wamid.SDFADSf23sfasdafasdfa')).not_to be_present

        expect(Redis::Alfred.get(key)).to be_truthy
        Redis::Alfred.delete(key)
      end
    end
  end
end
