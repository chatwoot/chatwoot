require 'rails_helper'

describe Whatsapp::IncomingMessageService do
  describe '#perform' do
    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
    end

    after do
      # The atomic dedup lock lives in Redis and is not rolled back by
      # transactional fixtures. Clean up any keys created during the test.
      Redis::Alfred.scan_each(match: 'MESSAGE_SOURCE_KEY::*') do |key|
        Redis::Alfred.delete(key)
      end
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

      it 'stores the external_created_at timestamp from the message' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        message = whatsapp_channel.inbox.messages.first
        expect(message.external_created_at).to eq(1_633_034_394)
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
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
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

      it 'will not create duplicate conversations when same message is received for new contact' do
        # First call creates contact, conversation and message
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.count).to eq(1)

        # Second call with same message ID should not create duplicate conversation
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.count).to eq(1)
      end

      it 'will not create duplicate conversations when same message is processed concurrently' do
        # Simulate concurrent processing by having Redis key cleared before second call
        # but message not yet visible in database due to transaction isolation
        service1 = described_class.new(inbox: whatsapp_channel.inbox, params: params)
        service2 = described_class.new(inbox: whatsapp_channel.inbox, params: params)

        # Process first message
        service1.perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)

        # Even if we clear the Redis key manually, should still not create duplicates
        key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: params[:messages].first[:id])
        Redis::Alfred.delete(key)

        # Second call should check database and find existing message
        service2.perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.count).to eq(1)
      end

      it 'prevents race condition with atomic lock when two requests arrive simultaneously' do
        # This test simulates the exact race condition that was causing duplicate conversations
        # Two concurrent webhook deliveries for the same message should result in only one being processed
        threads_started = Concurrent::CountDownLatch.new(2)

        thread1 = Thread.new do
          threads_started.count_down
          threads_started.wait # Wait for both threads to be ready
          service = described_class.new(inbox: whatsapp_channel.inbox, params: params)
          service.perform
        end

        thread2 = Thread.new do
          threads_started.count_down
          threads_started.wait # Wait for both threads to be ready
          service = described_class.new(inbox: whatsapp_channel.inbox, params: params)
          service.perform
        end

        thread1.join
        thread2.join

        # Only one conversation and one message should exist
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.count).to eq(1)
      end

      it 'only allows one of two concurrent requests to process the same message' do
        # Simulates atomic SETNX: first caller gets the lock, second is rejected
        message_source_key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{whatsapp_channel.inbox.id}_#{params[:messages].first[:id]}")
        lock_acquired = false

        # Allow all Redis::Alfred calls (contact lock uses different keys)
        allow(Redis::Alfred).to receive(:set).and_call_original
        allow(Redis::Alfred).to receive(:delete).and_call_original

        # Stub message lock specifically
        allow(Redis::Alfred).to receive(:set).with(message_source_key, true, nx: true, ex: 1.day) do
          result = !lock_acquired
          lock_acquired = true
          result
        end

        service1 = described_class.new(inbox: whatsapp_channel.inbox, params: params)
        service2 = described_class.new(inbox: whatsapp_channel.inbox, params: params)

        # Both bypass find_message_by_source_id (simulating race before DB commit)
        allow(service1).to receive(:find_message_by_source_id).and_return(nil)
        allow(service2).to receive(:find_message_by_source_id).and_return(nil)

        service1.perform
        service2.perform

        expect(whatsapp_channel.inbox.messages.count).to eq(1)
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
      end

      it 'clears lock outside transaction to prevent race conditions' do
        # Bug: lock was cleared INSIDE transaction before commit, allowing:
        # 1. Request A creates message, clears lock (transaction uncommitted)
        # 2. Request B acquires lock, can't see A's uncommitted message
        # 3. Both create duplicates
        #
        # Fix: clear lock in ensure block AFTER transaction commits
        message_source_key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{whatsapp_channel.inbox.id}_#{params[:messages].first[:id]}")
        lock_cleared_at_depth = nil

        # Allow all Redis::Alfred calls (contact lock uses different keys)
        allow(Redis::Alfred).to receive(:set).and_call_original
        allow(Redis::Alfred).to receive(:delete).and_call_original

        # Stub message lock specifically
        allow(Redis::Alfred).to receive(:set).with(message_source_key, true, nx: true, ex: 1.day).and_return(true)
        allow(Redis::Alfred).to receive(:delete).with(message_source_key) do
          lock_cleared_at_depth = ActiveRecord::Base.connection.open_transactions
        end

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        # Depth 1 = only RSpec's wrapper transaction, meaning our transaction completed
        expect(lock_cleared_at_depth).to eq(1),
                                         "Lock cleared at depth #{lock_cleared_at_depth}, expected 1. " \
                                         'Lock must be cleared AFTER transaction commits to prevent duplicates.'
      end

      it 'creates message in second inbox when same source_id exists in different inbox' do
        # Create a message with same source_id in a different inbox
        other_whatsapp_channel = create(:channel_whatsapp, sync_templates: false)
        other_inbox = other_whatsapp_channel.inbox
        other_contact = create(:contact, account: other_inbox.account)
        other_contact_inbox = create(:contact_inbox, inbox: other_inbox, contact: other_contact)
        other_conversation = create(:conversation, inbox: other_inbox, contact_inbox: other_contact_inbox)
        create(:message, conversation: other_conversation, inbox: other_inbox, source_id: params[:messages].first[:id])

        # Should still create message in our inbox since source_id check should be inbox-scoped
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.count).to eq(1)
      end

      it 'acquires contact-level lock to prevent album race conditions' do
        # When multiple messages from same contact arrive simultaneously (e.g., album),
        # the contact lock prevents race conditions in conversation creation.
        # This test verifies the lock is actually being acquired.
        phone_number = '2423423243'
        contact_lock_key = "WHATSAPP::CONTACT_LOCK::#{whatsapp_channel.inbox.id}_#{phone_number}"

        allow(Redis::Alfred).to receive(:set).and_call_original
        allow(Redis::Alfred).to receive(:delete).and_call_original

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(Redis::Alfred).to have_received(:set).with(contact_lock_key, 1, nx: true, ex: 5.seconds)
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

      it 'sets is_recorded_audio metadata for voice messages' do
        stub_request(:get, whatsapp_channel.media_url('b1c68f38-8734-4ad3-b4a1-ef0c10d683')).to_return(
          status: 200,
          body: File.read('spec/assets/sample.mp3'),
          headers: {}
        )
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => 'SDFADSf23sfasdafasdfa',
                           'audio' => { 'id' => 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                                        'mime_type' => 'audio/mp3',
                                        'sha256' => 'fa2820256f2cd3f2df03fa247d7b01e79d3fe794344aadcea08cee06bcce3c94',
                                        'voice' => true },
                           'timestamp' => '1633034394', 'type' => 'audio' }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(whatsapp_channel.inbox.messages.first.attachments.first.meta['is_recorded_audio']).to be true
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

        m1 = whatsapp_channel.inbox.messages.first
        expect(m1.content).to eq('Apple Inc.')
        expect(m1.attachments.first.fallback_title).to eq('+911800')
        expect(m1.attachments.first.meta).to eq({})

        m2 = whatsapp_channel.inbox.messages.last
        expect(m2.content).to eq('Chatwoot')
        expect(m2.attachments.first.meta).to eq({ 'firstName' => 'Chatwoot' })
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

    describe 'When the incoming waid is an Argentine number with 9 after country code' do
      let(:wa_id) { '5491123456789' }

      it 'creates appropriate conversations, message and contacts if contact does not exist' do
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Test')
        expect(whatsapp_channel.inbox.contact_inboxes.first.source_id).to eq(wa_id)
      end

      it 'appends to existing contact if contact inbox exists with normalized format' do
        # Normalized format removes the 9 after country code
        normalized_wa_id = '541123456789'
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: normalized_wa_id)
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        # message appended to the last conversation
        expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
        # should use the normalized wa_id from existing contact
        expect(whatsapp_channel.inbox.contact_inboxes.first.source_id).to eq(normalized_wa_id)
      end
    end

    describe 'When incoming waid is an Argentine number without 9 after country code' do
      let(:wa_id) { '541123456789' }

      context 'when a contact inbox exists with the same format' do
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

      context 'when a contact inbox does not exist' do
        it 'creates contact inbox with the incoming waid' do
          described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
          expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
          expect(Contact.all.first.name).to eq('Sojan Jose')
          expect(whatsapp_channel.inbox.messages.first.content).to eq('Test')
          expect(whatsapp_channel.inbox.contact_inboxes.first.source_id).to eq(wa_id)
        end
      end
    end

    describe 'when another worker already holds the dedup lock' do
      it 'skips message creation' do
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
        # Key is scoped by inbox.id to prevent cross-inbox lock collisions
        key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{whatsapp_channel.inbox.id}_wamid.SDFADSf23sfasdafasdfa")

        Redis::Alfred.setex(key, true)
        expect(Redis::Alfred.get(key)).to be_truthy

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.messages.count).to eq(0)
      ensure
        key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: 'wamid.SDFADSf23sfasdafasdfa')
        Redis::Alfred.delete(key)
      end
    end

    context 'when profile name is available for contact updates' do
      let(:wa_id) { '1234567890' }
      let(:phone_number) { "+#{wa_id}" }

      it 'updates existing contact name when current name matches phone number' do
        # Create contact with phone number as name
        existing_contact = create(:contact,
                                  account: whatsapp_channel.inbox.account,
                                  name: phone_number,
                                  phone_number: phone_number)
        create(:contact_inbox,
               contact: existing_contact,
               inbox: whatsapp_channel.inbox,
               source_id: wa_id)

        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Jane Smith' }, 'wa_id' => wa_id }],
          'messages' => [{ 'from' => wa_id, 'id' => 'message123', 'text' => { 'body' => 'Hello' },
                           'timestamp' => '1633034394', 'type' => 'text' }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        existing_contact.reload
        expect(existing_contact.name).to eq('Jane Smith')
      end

      it 'does not update contact name when current name is different from phone number' do
        # Create contact with human name
        existing_contact = create(:contact,
                                  account: whatsapp_channel.inbox.account,
                                  name: 'John Doe',
                                  phone_number: phone_number)
        create(:contact_inbox,
               contact: existing_contact,
               inbox: whatsapp_channel.inbox,
               source_id: wa_id)

        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Jane Smith' }, 'wa_id' => wa_id }],
          'messages' => [{ 'from' => wa_id, 'id' => 'message123', 'text' => { 'body' => 'Hello' },
                           'timestamp' => '1633034394', 'type' => 'text' }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        existing_contact.reload
        expect(existing_contact.name).to eq('John Doe') # Should not change
      end

      it 'updates contact name when current name matches formatted phone number' do
        formatted_number = TelephoneNumber.parse(phone_number).international_number

        # Create contact with formatted phone number as name
        existing_contact = create(:contact,
                                  account: whatsapp_channel.inbox.account,
                                  name: formatted_number,
                                  phone_number: phone_number)
        create(:contact_inbox,
               contact: existing_contact,
               inbox: whatsapp_channel.inbox,
               source_id: wa_id)

        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Alice Johnson' }, 'wa_id' => wa_id }],
          'messages' => [{ 'from' => wa_id, 'id' => 'message123', 'text' => { 'body' => 'Hello' },
                           'timestamp' => '1633034394', 'type' => 'text' }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        existing_contact.reload
        expect(existing_contact.name).to eq('Alice Johnson')
      end

      it 'does not update when profile name is blank' do
        # Create contact with phone number as name
        existing_contact = create(:contact,
                                  account: whatsapp_channel.inbox.account,
                                  name: phone_number,
                                  phone_number: phone_number)
        create(:contact_inbox,
               contact: existing_contact,
               inbox: whatsapp_channel.inbox,
               source_id: wa_id)

        params = {
          'contacts' => [{ 'profile' => { 'name' => '' }, 'wa_id' => wa_id }],
          'messages' => [{ 'from' => wa_id, 'id' => 'message123', 'text' => { 'body' => 'Hello' },
                           'timestamp' => '1633034394', 'type' => 'text' }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        existing_contact.reload
        expect(existing_contact.name).to eq(phone_number) # Should not change
      end
    end
  end
end
