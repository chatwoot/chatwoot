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

      it 'appends to last conversation when if conversation already exists' do
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        2.times.each { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact) }
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(3)
        # message appended to the last conversation
        expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
      end

      it 'reopen last conversation if last conversation is resolved and lock to single conversation is enabled' do
        whatsapp_channel.inbox.update(lock_to_single_conversation: true)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
        last_conversation.update(status: 'resolved')
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        # message appended to the last conversation
        expect(last_conversation.messages.last.content).to eq(params[:messages].first[:text][:body])
        expect(last_conversation.reload.status).to eq('open')
      end

      it 'creates a new conversation if last conversation is resolved and lock to single conversation is disabled' do
        whatsapp_channel.inbox.update(lock_to_single_conversation: false)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
        last_conversation.update(status: 'resolved')
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        # new conversation should be created
        expect(whatsapp_channel.inbox.conversations.count).to eq(2)
        expect(contact_inbox.conversations.last.messages.last.content).to eq(params[:messages].first[:text][:body])
      end

      it 'will not create a new conversation if last conversation is not resolved and lock to single conversation is disabled' do
        whatsapp_channel.inbox.update(lock_to_single_conversation: false)
        contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: params[:messages].first[:from])
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
        last_conversation.update(status: Conversation.statuses.except('resolved').keys.sample)
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

      it 'creates a contact and conversation when only BSUID is present' do
        params = {
          'contacts' => [{
            'profile' => { 'name' => 'Muhsin', 'username' => 'muhsin' },
            'user_id' => 'IN.2081978709342942',
            'parent_user_id' => 'IN.ENT.9081726354'
          }],
          'messages' => [{
            'from_user_id' => 'IN.2081978709342942',
            'from_parent_user_id' => 'IN.ENT.9081726354',
            'id' => 'wamid.bsuid-only-message',
            'text' => { 'body' => 'testing bsuid' },
            'timestamp' => '1778579582',
            'type' => 'text'
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

        contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: 'IN.2081978709342942')
        contact = contact_inbox.contact
        parent_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: 'IN.ENT.9081726354')
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.first.content).to eq('testing bsuid')
        expect(contact).to have_attributes(name: 'Muhsin', phone_number: nil)
        expect(contact.additional_attributes).to include(
          'social_whatsapp_user_name' => 'muhsin',
          'social_profiles' => { 'whatsapp' => 'muhsin' }
        )
        expect(parent_contact_inbox.contact).to eq(contact)
      end

      it 'links phone and BSUID source ids to the same contact' do
        phone_with_bsuid_params = {
          'contacts' => [{ 'profile' => { 'name' => 'Muhsin' }, 'wa_id' => '919745786257', 'user_id' => 'IN.2081978709342942' }],
          'messages' => [{
            'from' => '919745786257',
            'from_user_id' => 'IN.2081978709342942',
            'id' => 'wamid.phone-bsuid-message',
            'text' => { 'body' => 'phone and bsuid' },
            'timestamp' => '1778579582',
            'type' => 'text'
          }]
        }.with_indifferent_access
        bsuid_only_params = {
          'contacts' => [{ 'profile' => { 'name' => 'Muhsin' }, 'user_id' => 'IN.2081978709342942' }],
          'messages' => [{
            'from_user_id' => 'IN.2081978709342942',
            'id' => 'wamid.bsuid-follow-up-message',
            'text' => { 'body' => 'bsuid only' },
            'timestamp' => '1778579583',
            'type' => 'text'
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform
        contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: '919745786257')
        bsuid_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: 'IN.2081978709342942')

        expect { described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_only_params).perform }.not_to raise_error
        expect(whatsapp_channel.inbox.contact_inboxes.count).to eq(2)
        expect(whatsapp_channel.inbox.messages.pluck(:content)).to contain_exactly('phone and bsuid', 'bsuid only')
        expect(bsuid_contact_inbox.contact).to eq(contact_inbox.contact)
      end

      it 'backfills contact phone number when a phone arrives after BSUID-only creation' do
        bsuid_only_params = {
          'contacts' => [{ 'profile' => { 'name' => 'Muhsin' }, 'user_id' => 'IN.2081978709342942' }],
          'messages' => [{
            'from_user_id' => 'IN.2081978709342942',
            'id' => 'wamid.bsuid-first-message',
            'text' => { 'body' => 'bsuid first' },
            'timestamp' => '1778579582',
            'type' => 'text'
          }]
        }.with_indifferent_access
        phone_with_bsuid_params = {
          'contacts' => [{ 'profile' => { 'name' => 'Muhsin' }, 'wa_id' => '919745786257', 'user_id' => 'IN.2081978709342942' }],
          'messages' => [{
            'from' => '919745786257',
            'from_user_id' => 'IN.2081978709342942',
            'id' => 'wamid.phone-follow-up-message',
            'text' => { 'body' => 'phone follow up' },
            'timestamp' => '1778579583',
            'type' => 'text'
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_only_params).perform
        bsuid_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: 'IN.2081978709342942')

        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform

        phone_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: '919745786257')
        expect(phone_contact_inbox.contact).to eq(bsuid_contact_inbox.contact)
        expect(bsuid_contact_inbox.contact.reload.phone_number).to eq('+919745786257')
      end

      it 'keeps cloud BSUID source ids in the Meta-provided shape' do
        service = described_class.new(inbox: whatsapp_channel.inbox, params: params)

        expect(service.send(:whatsapp_source_id, 'whatsapp:IN.2081978709342942')).to eq('whatsapp:IN.2081978709342942')
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

      it 'stores type unsupported as a placeholder message so the conversation is not headless' do
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{
            'errors' => [{ 'code': 131_051, 'title': 'Message type is currently not supported.' }],
            :from => '2423423243', :id => 'wamid.SDFADSf23sfasdafasdfa',
            :timestamp => '1667047370', :type => 'unsupported'
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(Contact.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.count).to eq(1)
        message = whatsapp_channel.inbox.messages.last
        expect(message.content).to eq('This message is unavailable.')
        expect(message.content_attributes['is_unsupported']).to be(true)
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
        create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
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

      it 'stores BSUID source ids from status contacts' do
        bsuid = 'IN.2081978709342942'
        parent_bsuid = 'IN.ENT.9081726354'
        status_params = {
          'contacts' => [{ 'wa_id' => from, 'user_id' => bsuid, 'parent_user_id' => parent_bsuid }],
          'statuses' => [{ 'recipient_id' => from, 'id' => from, 'status' => 'delivered' }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: status_params).perform

        source_rows = whatsapp_channel.inbox.contact_inboxes.where(source_id: [from, bsuid, parent_bsuid]).pluck(:source_id, :contact_id)
        expect(source_rows).to contain_exactly(
          [from, contact_inbox.contact_id],
          [bsuid, contact_inbox.contact_id],
          [parent_bsuid, contact_inbox.contact_id]
        )
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
      let(:contact) { create(:contact, account: whatsapp_channel.account, name: 'Sojan Jose', phone_number: '+2423423243') }
      let(:contact_inbox) do
        create(:contact_inbox, contact: contact, inbox: whatsapp_channel.inbox, source_id: '2423423243')
      end
      let(:conversation) do
        create(:conversation, account: whatsapp_channel.account, inbox: whatsapp_channel.inbox, contact: contact, contact_inbox: contact_inbox)
      end
      let(:context_id) { 'wamid.originating-interactive-message' }
      let(:origin_message_type) { :outgoing }
      let(:reply_id) { snapshot.dig('action', 'buttons', 0, 'delivery_id') }
      let(:reply_type) { 'button_reply' }
      let(:provider_reply) { { 'id' => reply_id, 'title' => 'Confirm' } }
      let(:snapshot) do
        JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/button.json').read).tap do |value|
          value.dig('action', 'buttons', 0)['preset_option_id'] = '6ee65bd4-6ef0-4a7c-b5d1-d55ac85b9418'
        end
      end
      let!(:outgoing_message) do
        create(:message, account: whatsapp_channel.account, inbox: whatsapp_channel.inbox, conversation: conversation,
                         message_type: origin_message_type, source_id: context_id,
                         content_attributes: { 'whatsapp_interactive' => snapshot })
      end
      let(:interactive_params) do
        {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{
            'context' => { 'id' => context_id },
            'from' => '2423423243',
            'id' => 'wamid.inbound-interactive-message',
            'interactive' => { reply_type => provider_reply, 'type' => reply_type },
            'timestamp' => '1633034394',
            'type' => 'interactive'
          }]
        }.with_indifferent_access
      end

      it 'persists a readable button reply and its exact snapshot identity alongside threading' do
        described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

        message = conversation.messages.last
        expect(message.content).to eq('Confirm')
        expect(message.content_attributes).to include(
          'in_reply_to' => outgoing_message.id,
          'in_reply_to_external_id' => context_id,
          'whatsapp_interactive_reply' => {
            'type' => 'button_reply',
            'delivery_id' => reply_id,
            'title' => 'Confirm',
            'context_id' => context_id,
            'originating_message_id' => outgoing_message.id,
            'preset_option_id' => '6ee65bd4-6ef0-4a7c-b5d1-d55ac85b9418'
          }
        )
      end

      context 'with a list reply' do
        let(:reply_type) { 'list_reply' }
        let(:reply_id) { snapshot.dig('action', 'sections', 0, 'rows', 0, 'delivery_id') }
        let(:provider_reply) { { 'id' => reply_id, 'title' => 'Pasta', 'description' => 'Tomato and basil' } }
        let(:snapshot) do
          JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/list.json').read).tap do |value|
            value.dig('action', 'sections', 0, 'rows', 0)['preset_option_id'] = 'd6de08cc-03d3-49f4-9cb6-19d5c76efdf5'
          end
        end

        it 'persists the provider description and exact list-row identity' do
          described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

          message = conversation.messages.last
          expect(message.content).to eq('Pasta')
          expect(message.content_attributes['whatsapp_interactive_reply']).to eq(
            'type' => 'list_reply',
            'delivery_id' => reply_id,
            'title' => 'Pasta',
            'description' => 'Tomato and basil',
            'context_id' => context_id,
            'originating_message_id' => outgoing_message.id,
            'preset_option_id' => 'd6de08cc-03d3-49f4-9cb6-19d5c76efdf5'
          )
        end

        it 'omits the optional description when Meta does not send it' do
          provider_reply.delete('description')

          described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

          expect(conversation.messages.last.content_attributes['whatsapp_interactive_reply']).not_to have_key('description')
        end
      end

      context 'with a carousel quick reply' do
        let(:reply_id) { snapshot.dig('action', 'cards', 1, 'action', 'buttons', 0, 'delivery_id') }
        let(:provider_reply) { { 'id' => reply_id, 'title' => 'Choose' } }
        let(:snapshot) do
          JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/carousel_quick_reply.json').read).tap do |value|
            value.dig('action', 'cards', 1, 'action', 'buttons', 0)['preset_option_id'] = '957dd2f4-254f-4a7d-902c-9e89347c69d0'
          end
        end

        it 'maps the globally unique delivery ID to its historical card and preset option' do
          described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

          expect(conversation.messages.last.content_attributes['whatsapp_interactive_reply']).to include(
            'originating_message_id' => outgoing_message.id,
            'preset_option_id' => '957dd2f4-254f-4a7d-902c-9e89347c69d0',
            'card_index' => 1
          )
        end
      end

      context 'when the delivery ID does not exist in the context-linked snapshot' do
        let(:reply_id) { 'reply_unknown' }

        it 'keeps provider evidence and message context without inventing option or card identity' do
          described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

          reply = conversation.messages.last.content_attributes['whatsapp_interactive_reply']
          expect(reply).to include(
            'delivery_id' => 'reply_unknown',
            'title' => 'Confirm',
            'context_id' => context_id,
            'originating_message_id' => outgoing_message.id
          )
          expect(reply).not_to have_key('preset_option_id')
          expect(reply).not_to have_key('card_index')
        end
      end

      context 'when the context-linked message is incoming' do
        let(:origin_message_type) { :incoming }

        it 'does not trust its shaped snapshot for preset identity' do
          described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

          reply = conversation.messages.last.content_attributes['whatsapp_interactive_reply']
          expect(reply).to include('originating_message_id' => outgoing_message.id)
          expect(reply).not_to have_key('preset_option_id')
          expect(reply).not_to have_key('card_index')
        end
      end

      context 'when the context-linked snapshot has an unsupported schema version' do
        let(:snapshot) do
          JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/button.json').read).tap do |value|
            value['schema_version'] = 2
            value.dig('action', 'buttons', 0)['preset_option_id'] = '6ee65bd4-6ef0-4a7c-b5d1-d55ac85b9418'
          end
        end

        it 'does not trust its preset identity' do
          described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

          reply = conversation.messages.last.content_attributes['whatsapp_interactive_reply']
          expect(reply).to include('originating_message_id' => outgoing_message.id)
          expect(reply).not_to have_key('preset_option_id')
          expect(reply).not_to have_key('card_index')
        end
      end

      context 'when the provider context does not identify a stored message' do
        let(:context_id) { 'wamid.missing-originating-message' }

        it 'keeps readable provider evidence and context without inventing message identity' do
          outgoing_message.update!(source_id: 'wamid.different-originating-message')

          described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

          message = conversation.messages.last
          reply = message.content_attributes['whatsapp_interactive_reply']
          expect(message.content).to eq('Confirm')
          expect(reply).to include('delivery_id' => reply_id, 'title' => 'Confirm', 'context_id' => context_id)
          expect(reply).not_to have_key('originating_message_id')
          expect(reply).not_to have_key('preset_option_id')
          expect(reply).not_to have_key('card_index')
        end
      end

      it 'uses only the context-linked historical snapshot when a newer message reuses readable content' do
        create(:message, account: whatsapp_channel.account, inbox: whatsapp_channel.inbox, conversation: conversation,
                         message_type: :outgoing, source_id: 'wamid.newer-interactive-message',
                         content_attributes: {
                           'whatsapp_interactive' => snapshot.deep_dup.tap do |value|
                             value.dig('action', 'buttons', 0)['preset_option_id'] = '5d4e0ff7-d8f2-405f-82bc-80414ae29353'
                           end
                         })

        described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

        expect(conversation.messages.last.content_attributes.dig('whatsapp_interactive_reply', 'preset_option_id'))
          .to eq('6ee65bd4-6ef0-4a7c-b5d1-d55ac85b9418')
      end

      it 'does not add a structured selection for an unrelated interactive subtype' do
        interactive_params[:messages].first[:interactive] = {
          'type' => 'nfm_reply',
          'nfm_reply' => { 'name' => 'flow', 'body' => 'Submitted', 'response_json' => '{"answer":"yes"}' }
        }

        described_class.new(inbox: whatsapp_channel.inbox, params: interactive_params).perform

        message = conversation.messages.last
        expect(message.content_attributes).to include('whatsapp_flow_response')
        expect(message.content_attributes).not_to have_key('whatsapp_interactive_reply')
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

      it 'truncates long fallback titles to avoid dropping location messages' do
        long_place_name = [
          'Gremi de Fusters, 33, Edificio VIP Asima, Piso 2, Local 2, Norte',
          '07009 Poligon industrial de Son Castello, Illes Balears, Espana'
        ].join(', ')
        source_id = 'wamid.long-location-fallback-title'
        params = {
          'contacts' => [{ 'profile' => { 'name' => 'Sojan Jose' }, 'wa_id' => '2423423243' }],
          'messages' => [{ 'from' => '2423423243', 'id' => source_id,
                           'location' => { 'id' => 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                                           :address => long_place_name,
                                           :latitude => 37.7893768,
                                           :longitude => -122.3895553,
                                           :name => long_place_name,
                                           :url => 'http://location_url.test' },
                           'timestamp' => '1633034394', 'type' => 'location' }]
        }.with_indifferent_access

        expect { described_class.new(inbox: whatsapp_channel.inbox, params: params).perform }
          .to change { Message.where(source_id: source_id).count }.from(0).to(1)

        location_attachment = Message.find_by!(source_id: source_id).attachments.first
        expect(location_attachment.fallback_title).to eq("#{long_place_name}, #{long_place_name}".first(255))
        expect(location_attachment.fallback_title.length).to eq(255)
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
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
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
          last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
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
          last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
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
        last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
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
          last_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox, contact: contact_inbox.contact)
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

        # Simulate another worker holding the lock
        lock = Whatsapp::MessageDedupLock.new('wamid.SDFADSf23sfasdafasdfa')
        expect(lock.acquire!).to be_truthy

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
