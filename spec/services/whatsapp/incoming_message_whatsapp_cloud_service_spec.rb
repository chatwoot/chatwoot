require 'rails_helper'

describe Whatsapp::IncomingMessageWhatsappCloudService do
  describe '#perform' do
    after do
      Redis::Alfred.scan_each(match: 'MESSAGE_SOURCE_KEY::*') { |key| Redis::Alfred.delete(key) }
    end

    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
    let(:sender_number) { '2423423243' }
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              contacts: [{ profile: { name: 'Sojan Jose' }, wa_id: sender_number }],
              messages: [{
                from: sender_number,
                image: {
                  id: 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                  mime_type: 'image/jpeg',
                  sha256: '29ed500fa64eb55fc19dc4124acb300e5dcca0f822a301ae99944db',
                  caption: 'Check out my product!'
                },
                timestamp: '1664799904', type: 'image'
              }]
            }
          }]
        }]
      }.with_indifferent_access
    end

    context 'when valid attachment message params' do
      it 'creates appropriate conversations, message and contacts' do
        stub_media_url_request
        stub_sample_png_request
        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect_conversation_created
        expect_contact_name
        expect_message_content
        expect_message_has_attachment
      end

      it 'increments reauthorization count if fetching attachment fails' do
        stub_request(
          :get,
          whatsapp_channel.media_url('b1c68f38-8734-4ad3-b4a1-ef0c10d683')
        ).to_return(
          status: 401
        )

        described_class.new(inbox: whatsapp_channel.inbox, params: params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect_contact_name
        expect(whatsapp_channel.inbox.messages.first.content).to eq('Check out my product!')
        expect(whatsapp_channel.inbox.messages.first.attachments.present?).to be false
        expect(whatsapp_channel.authorization_error_count).to eq(1)
      end
    end

    context 'when document attachment includes an accented filename' do
      let(:document_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Sojan Jose' }, wa_id: '2423423243' }],
                messages: [{
                  from: '2423423243',
                  document: {
                    id: 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                    mime_type: 'application/pdf',
                    filename: 'Currículum café.pdf',
                    caption: 'My résumé'
                  },
                  timestamp: '1664799904', type: 'document'
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      it 'preserves the original filename from the payload' do
        stub_media_url_request
        stub_sample_png_request
        described_class.new(inbox: whatsapp_channel.inbox, params: document_params).perform

        attachment = whatsapp_channel.inbox.messages.first.attachments.first
        expect(attachment.file.filename.to_s).to eq('Currículum café.pdf')
      end
    end

    context 'when a contact submits a WhatsApp Flow response' do
      let(:response_json) do
        {
          flow_token: 'flow-correlation-token',
          rating: 'excellent',
          comments: 'Great support',
          appointment: { day: 'Monday', windows: %w[morning afternoon] }
        }.to_json
      end

      let(:flow_response_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Flow Contact' }, wa_id: '2423423243' }],
                messages: [{
                  context: { from: whatsapp_channel.phone_number, id: 'wamid.original-flow-message' },
                  from: '2423423243',
                  id: 'wamid.flow-response-message',
                  timestamp: '1664799904',
                  type: 'interactive',
                  interactive: {
                    type: 'nfm_reply',
                    nfm_reply: {
                      name: 'flow',
                      body: 'Sent',
                      response_json: response_json
                    }
                  }
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      it 'stores the complete response as a visible incoming message' do
        described_class.new(inbox: whatsapp_channel.inbox, params: flow_response_params).perform

        message = whatsapp_channel.inbox.messages.last
        flow_response = message.content_attributes['whatsapp_flow_response']

        expect(message).to have_attributes(
          content: 'Submitted a flow response',
          content_type: 'text',
          message_type: 'incoming',
          source_id: 'wamid.flow-response-message'
        )
        expect(flow_response).to eq(
          'name' => 'flow',
          'body' => 'Sent',
          'response_json' => {
            'flow_token' => 'flow-correlation-token',
            'rating' => 'excellent',
            'comments' => 'Great support',
            'appointment' => { 'day' => 'Monday', 'windows' => %w[morning afternoon] }
          }
        )
        expect(message.webhook_data[:content_attributes]['whatsapp_flow_response']).to eq(flow_response)
      end

      context 'when response_json contains invalid JSON' do
        let(:response_json) { '{invalid-json' }

        it 'stores the raw response without dropping the message' do
          described_class.new(inbox: whatsapp_channel.inbox, params: flow_response_params).perform

          message = whatsapp_channel.inbox.messages.last

          expect(message.content).to eq('Submitted a flow response')
          expect(message.content_attributes.dig('whatsapp_flow_response', 'response_json')).to eq('{invalid-json')
          expect(message.webhook_data[:content_attributes].dig('whatsapp_flow_response', 'response_json')).to eq('{invalid-json')
        end
      end

      context 'when response_json is missing' do
        let(:response_json) { nil }

        it 'stores the flow metadata without dropping the message' do
          described_class.new(inbox: whatsapp_channel.inbox, params: flow_response_params).perform

          message = whatsapp_channel.inbox.messages.last

          expect(message.content).to eq('Submitted a flow response')
          expect(message.content_attributes['whatsapp_flow_response']).to eq(
            'name' => 'flow',
            'body' => 'Sent'
          )
        end
      end
    end

    context 'when invalid attachment message params' do
      let(:error_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Sojan Jose' }, wa_id: sender_number }],
                messages: [{
                  from: sender_number,
                  image: {
                    id: 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                    mime_type: 'image/jpeg',
                    sha256: '29ed500fa64eb55fc19dc4124acb300e5dcca0f822a301ae99944db',
                    caption: 'Check out my product!'
                  },
                  errors: [{
                    code: 400,
                    details: 'Last error was: ServerThrottle. Http request error: HTTP response code said error. See logs for details',
                    title: 'Media download failed: Not retrying as download is not retriable at this time'
                  }],
                  timestamp: '1664799904', type: 'image'
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      it 'with attachment errors' do
        described_class.new(inbox: whatsapp_channel.inbox, params: error_params).perform
        expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
        expect_contact_name
        expect(whatsapp_channel.inbox.messages.count).to eq(0)
      end
    end

    context 'when BSUID identifiers are present' do
      let(:phone_with_bsuid_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Muhsin' }, wa_id: '919745786257', user_id: 'IN.2081978709342942' }],
                messages: [{
                  from: '919745786257',
                  from_user_id: 'IN.2081978709342942',
                  id: 'wamid.cloud-phone-bsuid-message',
                  text: { body: 'phone and bsuid' },
                  timestamp: '1778579582',
                  type: 'text'
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end
      let(:bsuid_only_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Muhsin' }, user_id: 'IN.2081978709342942' }],
                messages: [{
                  from_user_id: 'IN.2081978709342942',
                  id: 'wamid.cloud-bsuid-follow-up-message',
                  text: { body: 'bsuid only' },
                  timestamp: '1778579583',
                  type: 'text'
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      it 'creates the first conversation on the BSUID contact inbox when the phone number is absent' do
        described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_only_params).perform

        contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: 'IN.2081978709342942')
        conversation = whatsapp_channel.inbox.conversations.find_by!(contact_inbox: contact_inbox)

        expect(contact_inbox.contact.phone_number).to be_nil
        expect(conversation.messages.pluck(:content)).to contain_exactly('bsuid only')
      end

      it 'keeps a later mixed phone and BSUID payload on the existing BSUID conversation' do
        described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_only_params).perform
        original_conversation = whatsapp_channel.inbox.conversations.find_by!(contact_inbox: whatsapp_channel.inbox.contact_inboxes.find_by!(
          source_id: 'IN.2081978709342942'
        ))

        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform

        contact = original_conversation.contact
        phone_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: '919745786257')
        expect(phone_contact_inbox.contact).to eq(contact)
        expect(whatsapp_channel.inbox.conversations).to contain_exactly(original_conversation)
        expect(original_conversation.messages.pluck(:content)).to contain_exactly('bsuid only', 'phone and bsuid')
      end

      it 'creates a contact and conversation when only BSUID is present' do
        bsuid_params = {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{
                  profile: { name: 'Muhsin', username: 'muhsin' },
                  user_id: 'IN.2081978709342942',
                  parent_user_id: 'IN.ENT.9081726354'
                }],
                messages: [{
                  from_user_id: 'IN.2081978709342942',
                  from_parent_user_id: 'IN.ENT.9081726354',
                  id: 'wamid.cloud-bsuid-only-message',
                  text: { body: 'testing bsuid' },
                  timestamp: '1778579582',
                  type: 'text'
                }]
              }
            }]
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_params).perform

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
        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform
        contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: '919745786257')
        bsuid_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: 'IN.2081978709342942')

        expect { described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_only_params).perform }.not_to raise_error
        expect(whatsapp_channel.inbox.contact_inboxes.count).to eq(2)
        expect(whatsapp_channel.inbox.messages.pluck(:content)).to contain_exactly('phone and bsuid', 'bsuid only')
        expect(bsuid_contact_inbox.contact).to eq(contact_inbox.contact)
      end

      it 'opens the conversation on the phone contact inbox when a payload carries both identities' do
        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform

        phone_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: '919745786257')

        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.conversations.first.contact_inbox).to eq(phone_contact_inbox)
      end

      it 'moves to the BSUID contact inbox only when a follow-up omits the phone' do
        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform
        described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_only_params).perform

        phone_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: '919745786257')
        bsuid_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: 'IN.2081978709342942')

        expect(whatsapp_channel.inbox.conversations.count).to eq(2)
        expect(phone_contact_inbox.conversations.first.messages.pluck(:content)).to contain_exactly('phone and bsuid')
        expect(bsuid_contact_inbox.conversations.first.messages.pluck(:content)).to contain_exactly('bsuid only')
        expect(whatsapp_channel.inbox.messages.pluck(:content)).to contain_exactly('phone and bsuid', 'bsuid only')
      end

      it 'keeps an outgoing echo on the same conversation as the inbound message' do
        echo_params = {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              field: 'smb_message_echoes',
              value: {
                message_echoes: [{
                  from: whatsapp_channel.phone_number.delete('+'),
                  to: '919745786257',
                  to_user_id: 'IN.2081978709342942',
                  id: 'wamid.cloud-echo-message',
                  text: { body: 'echo reply' },
                  timestamp: '1778579584',
                  type: 'text'
                }]
              }
            }]
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform
        described_class.new(inbox: whatsapp_channel.inbox, params: echo_params, outgoing_echo: true).perform

        expect(whatsapp_channel.inbox.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.pluck(:content)).to contain_exactly('phone and bsuid', 'echo reply')
      end

      it 'leaves a conversation opened under the phone identity untouched' do
        phone_contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '919745786257')
        contact = phone_contact_inbox.contact
        phone_conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: phone_contact_inbox,
                                                   contact: contact, account: whatsapp_channel.inbox.account)
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.2081978709342942')

        described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_only_params).perform

        expect(phone_conversation.reload.contact_inbox).to eq(phone_contact_inbox)
        expect(contact.conversations.count).to eq(2)
      end

      it 'names a contact created by an echo after the phone number, not the identifier' do
        echo_params = {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              field: 'smb_message_echoes',
              value: {
                message_echoes: [{
                  from: whatsapp_channel.phone_number.delete('+'),
                  to: '919745786257',
                  to_user_id: 'IN.2081978709342942',
                  id: 'wamid.cloud-echo-first-event',
                  text: { body: 'first contact by echo' },
                  timestamp: '1778579585',
                  type: 'text'
                }]
              }
            }]
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: echo_params, outgoing_echo: true).perform

        expect(Contact.last.name).to eq('+919745786257')
        expect(whatsapp_channel.inbox.conversations.first.contact_inbox.source_id).to eq('919745786257')
      end

      it 'keeps a phone-backed contact on the phone conversation when a payload carries an identifier' do
        phone_contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '919745786257')
        contact = phone_contact_inbox.contact
        create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: phone_contact_inbox,
                              contact: contact, account: whatsapp_channel.inbox.account)

        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform

        bsuid_contact_inbox = whatsapp_channel.inbox.contact_inboxes.find_by!(source_id: 'IN.2081978709342942')

        expect(bsuid_contact_inbox.contact).to eq(contact)
        expect(contact.conversations.count).to eq(1)
        expect(whatsapp_channel.inbox.messages.last.conversation.contact_inbox).to eq(phone_contact_inbox)
      end

      it 'does not open a third conversation on the payload after that' do
        phone_contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '919745786257')
        contact = phone_contact_inbox.contact
        create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: phone_contact_inbox,
                              contact: contact, account: whatsapp_channel.inbox.account)

        described_class.new(inbox: whatsapp_channel.inbox, params: phone_with_bsuid_params).perform
        described_class.new(inbox: whatsapp_channel.inbox, params: bsuid_only_params).perform

        expect(contact.conversations.count).to eq(2)
      end

      context 'when a merged contact owns multiple WhatsApp identities' do
        let(:account) { whatsapp_channel.inbox.account }
        let!(:contact_a) { create(:contact, account: account, name: 'Customer A') }
        let!(:contact_b) { create(:contact, account: account, name: 'Customer B') }
        let!(:contact_inbox_a) do
          create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact_a, source_id: 'AE.QACUSTOMERA')
        end
        let!(:contact_inbox_b) do
          create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact_b, source_id: 'AE.QACUSTOMERB')
        end
        let!(:conversation_a) do
          create(:conversation, account: account, inbox: whatsapp_channel.inbox, contact: contact_a, contact_inbox: contact_inbox_a)
        end
        let!(:conversation_b) do
          create(:conversation, account: account, inbox: whatsapp_channel.inbox, contact: contact_b, contact_inbox: contact_inbox_b)
        end
        let(:customer_a_params) do
          {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              changes: [{
                value: {
                  contacts: [{ profile: { name: 'Customer A', username: 'shared-handle' }, user_id: 'AE.QACUSTOMERA' }],
                  messages: [{
                    from_user_id: 'AE.QACUSTOMERA', id: "wamid.cloud-merged-customer-a-#{SecureRandom.hex(8)}",
                    text: { body: 'message from customer A' }, timestamp: '1778579701', type: 'text'
                  }]
                }
              }]
            }]
          }.with_indifferent_access
        end
        let(:customer_b_params) do
          {
            phone_number: whatsapp_channel.phone_number,
            object: 'whatsapp_business_account',
            entry: [{
              changes: [{
                value: {
                  contacts: [{ profile: { name: 'Customer B', username: 'shared-handle' }, user_id: 'AE.QACUSTOMERB' }],
                  messages: [{
                    from_user_id: 'AE.QACUSTOMERB', id: "wamid.cloud-merged-customer-b-#{SecureRandom.hex(8)}",
                    text: { body: 'message from customer B' }, timestamp: '1778579702', type: 'text'
                  }]
                }
              }]
            }]
          }.with_indifferent_access
        end

        before do
          ContactMergeAction.new(account: account, base_contact: contact_a, mergee_contact: contact_b).perform
        end

        it 'routes each inbound message by its exact BSUID instead of shared contact metadata or recency' do
          described_class.new(inbox: whatsapp_channel.inbox, params: customer_b_params).perform
          described_class.new(inbox: whatsapp_channel.inbox, params: customer_a_params).perform

          expect(conversation_a.reload.messages.pluck(:content)).to contain_exactly('message from customer A')
          expect(conversation_b.reload.messages.pluck(:content)).to contain_exactly('message from customer B')
          expect(conversation_a.contact_inbox).to eq(contact_inbox_a)
          expect(conversation_b.contact_inbox).to eq(contact_inbox_b)
        end

        it 'reopens only the exact identity conversation when conversation locking is enabled' do
          whatsapp_channel.inbox.update!(lock_to_single_conversation: true)
          conversation_a.update!(status: :resolved)
          conversation_b.update!(status: :resolved)

          described_class.new(inbox: whatsapp_channel.inbox, params: customer_a_params).perform
          described_class.new(inbox: whatsapp_channel.inbox, params: customer_b_params).perform

          expect(whatsapp_channel.inbox.conversations.count).to eq(2)
          expect(conversation_a.reload).to have_attributes(status: 'open', contact_inbox: contact_inbox_a)
          expect(conversation_b.reload).to have_attributes(status: 'open', contact_inbox: contact_inbox_b)
        end

        it 'creates a new conversation for each exact identity when conversation locking is disabled' do
          whatsapp_channel.inbox.update!(lock_to_single_conversation: false)
          conversation_a.update!(status: :resolved)
          conversation_b.update!(status: :resolved)

          described_class.new(inbox: whatsapp_channel.inbox, params: customer_a_params).perform
          described_class.new(inbox: whatsapp_channel.inbox, params: customer_b_params).perform

          expect(contact_inbox_a.conversations.count).to eq(2)
          expect(contact_inbox_b.conversations.count).to eq(2)
          expect(contact_inbox_a.conversations.last.messages.pluck(:content)).to contain_exactly('message from customer A')
          expect(contact_inbox_b.conversations.last.messages.pluck(:content)).to contain_exactly('message from customer B')
        end
      end

      it 'does not merge or repoint contacts when identifiers in one payload conflict' do
        account = whatsapp_channel.inbox.account
        bsuid_contact = create(:contact, account: account, name: 'BSUID contact')
        phone_contact = create(:contact, account: account, name: 'Phone contact')
        bsuid_contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: bsuid_contact, source_id: 'AE.QACONFLICT')
        phone_contact_inbox = create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: phone_contact, source_id: '971501234567')
        bsuid_conversation = create(:conversation, account: account, inbox: whatsapp_channel.inbox, contact: bsuid_contact,
                                                   contact_inbox: bsuid_contact_inbox)
        phone_conversation = create(:conversation, account: account, inbox: whatsapp_channel.inbox, contact: phone_contact,
                                                   contact_inbox: phone_contact_inbox)
        conflicting_params = {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Conflicting identifiers' }, wa_id: '971501234567', user_id: 'AE.QACONFLICT' }],
                messages: [{
                  from: '971501234567', from_user_id: 'AE.QACONFLICT', id: 'wamid.cloud-conflicting-identifiers',
                  text: { body: 'route by phone when present' }, timestamp: '1778579800', type: 'text'
                }]
              }
            }]
          }]
        }.with_indifferent_access

        described_class.new(inbox: whatsapp_channel.inbox, params: conflicting_params).perform

        expect(phone_conversation.reload.messages.pluck(:content)).to contain_exactly('route by phone when present')
        expect(bsuid_conversation.reload.messages).to be_empty
        expect(bsuid_contact_inbox.reload.contact).to eq(bsuid_contact)
        expect(phone_contact_inbox.reload.contact).to eq(phone_contact)
      end
    end

    context 'when invalid params' do
      it 'will not throw error' do
        described_class.new(inbox: whatsapp_channel.inbox, params: { phone_number: whatsapp_channel.phone_number,
                                                                     object: 'whatsapp_business_account', entry: {} }).perform
        expect(whatsapp_channel.inbox.conversations.count).to eq(0)
        expect(Contact.find_by(phone_number: contact_phone_number)).to be_nil
        expect(whatsapp_channel.inbox.messages.count).to eq(0)
      end
    end

    context 'when message contains referral data' do
      let(:referral_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Mom' }, wa_id: '255718573302', user_id: 'TZ.1040042605869930' }],
                messages: [{
                  referral: {
                    source_url: 'https://fb.me/3TYpooaRT',
                    source_id: '52558118838064',
                    source_type: 'ad',
                    body: 'washa data tu',
                    headline: 'Diana Digital',
                    media_type: 'video',
                    video_url: 'https://www.facebook.com/reel/1438165771395493/',
                    thumbnail_url: 'https://scontent.xx.fbcdn.net/sample.jpg',
                    ctwa_clid: 'AfhcQdP2E4A8wWpeb1FqUzUi',
                    welcome_message: {
                      text: 'Hi! Please let us know how we can help you.'
                    }
                  },
                  from: '255718573302',
                  from_user_id: 'TZ.1040042605869930',
                  id: 'wamid.CTWA_REFERRAL_MESSAGE',
                  timestamp: '1780649766',
                  text: { body: 'Hello nielekeze' },
                  type: 'text'
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      it 'stores the referral payload in message content attributes' do
        described_class.new(inbox: whatsapp_channel.inbox, params: referral_params).perform

        message = whatsapp_channel.inbox.messages.last
        expect(message.content).to eq('Hello nielekeze')
        expect(message.content_attributes['referral']).to include(
          'source_url' => 'https://fb.me/3TYpooaRT',
          'source_id' => '52558118838064',
          'source_type' => 'ad',
          'body' => 'washa data tu',
          'headline' => 'Diana Digital',
          'media_type' => 'video',
          'video_url' => 'https://www.facebook.com/reel/1438165771395493/',
          'thumbnail_url' => 'https://scontent.xx.fbcdn.net/sample.jpg',
          'ctwa_clid' => 'AfhcQdP2E4A8wWpeb1FqUzUi',
          'welcome_message' => { 'text' => 'Hi! Please let us know how we can help you.' }
        )
      end

      it 'preserves the referral payload when the message contains contacts' do
        contacts_referral_params = referral_params.deep_dup
        parent_message = contacts_referral_params.dig(:entry, 0, :changes, 0, :value, :messages, 0)
        parent_message[:type] = 'contacts'
        parent_message.delete(:text)
        parent_message[:contacts] = [{
          name: {
            formatted_name: 'Diana Digital',
            first_name: 'Diana',
            last_name: 'Digital'
          },
          phones: [{ phone: '+255718573302' }]
        }]

        described_class.new(inbox: whatsapp_channel.inbox, params: contacts_referral_params).perform

        message = whatsapp_channel.inbox.messages.last
        expect(message.content).to eq('Diana Digital')
        expect(message.content_attributes['referral']).to include(
          'source_id' => '52558118838064',
          'headline' => 'Diana Digital',
          'ctwa_clid' => 'AfhcQdP2E4A8wWpeb1FqUzUi'
        )
      end
    end

    context 'when message is a reply (has context)' do
      let(:reply_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Pranav' }, wa_id: '16503071063' }],
                messages: [{
                  context: {
                    from: '16503071063',
                    id: 'wamid.ORIGINAL_MESSAGE_ID'
                  },
                  from: '16503071063',
                  id: 'wamid.REPLY_MESSAGE_ID',
                  timestamp: '1770407829',
                  text: { body: 'This is a reply' },
                  type: 'text'
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      context 'when the original message exists in Chatwoot' do
        it 'sets in_reply_to to reference the existing message' do
          # Create a conversation and the original message that will be replied to first
          contact = create(:contact, phone_number: '+16503071063', account: whatsapp_channel.account)
          contact_inbox = create(:contact_inbox, contact: contact, inbox: whatsapp_channel.inbox, source_id: '16503071063')
          conversation = create(:conversation, contact: contact, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox)

          original_message = create(:message,
                                    conversation: conversation,
                                    source_id: 'wamid.ORIGINAL_MESSAGE_ID',
                                    content: 'Original message')

          described_class.new(inbox: whatsapp_channel.inbox, params: reply_params).perform

          reply_message = whatsapp_channel.inbox.messages.last
          expect(reply_message.content).to eq('This is a reply')
          expect(reply_message.content_attributes['in_reply_to']).to eq(original_message.id)
          expect(reply_message.content_attributes['in_reply_to_external_id']).to eq('wamid.ORIGINAL_MESSAGE_ID')
        end
      end

      context 'when the original message does not exist in Chatwoot' do
        it 'does not set in_reply_to (discards the reply reference)' do
          described_class.new(inbox: whatsapp_channel.inbox, params: reply_params).perform

          reply_message = whatsapp_channel.inbox.messages.last
          expect(reply_message.content).to eq('This is a reply')
          expect(reply_message.content_attributes['in_reply_to']).to be_nil
          expect(reply_message.content_attributes['in_reply_to_external_id']).to be_nil
        end
      end
    end

    context 'when an identity-change system message is received' do
      let(:contact) { create(:contact, account: whatsapp_channel.inbox.account) }
      let(:system) do
        {
          type: 'user_changed_user_id',
          previous_user_id: 'IN.PREVIOUSBSUID',
          user_id: 'IN.CURRENTBSUID'
        }
      end

      let(:system_message_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              field: 'messages',
              value: {
                messaging_product: 'whatsapp',
                metadata: {
                  display_phone_number: whatsapp_channel.phone_number.delete('+'),
                  phone_number_id: whatsapp_channel.provider_config['phone_number_id']
                },
                messages: [{
                  id: 'wamid.SYSTEM_MESSAGE_ID',
                  timestamp: '1664799904',
                  type: 'system',
                  system: system
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      def rotate
        described_class.new(inbox: whatsapp_channel.inbox, params: system_message_params).perform
      end

      it 'records current regular and parent identifiers as aliases of the previous contact' do
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.ENT.PREVIOUSBSUID')
        system.merge!(
          previous_parent_user_id: 'IN.ENT.PREVIOUSBSUID',
          parent_user_id: 'IN.ENT.CURRENTBSUID'
        )

        rotate

        expect(whatsapp_channel.inbox.contact_inboxes.where(contact: contact).pluck(:source_id)).to contain_exactly(
          'IN.PREVIOUSBSUID', 'IN.ENT.PREVIOUSBSUID', 'IN.CURRENTBSUID', 'IN.ENT.CURRENTBSUID'
        )
      end

      it 'leaves existing conversations on the contact inbox that opened them' do
        previous = create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
        conversation = create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: previous,
                                             contact: previous.contact, account: whatsapp_channel.inbox.account)

        rotate

        expect(conversation.reload.contact_inbox).to eq(previous)
      end

      it 'does not create a visible message or conversation for the system event' do
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')

        expect { rotate }.to change(ContactInbox, :count).by(1)
        expect(whatsapp_channel.inbox.messages).to be_empty
        expect(whatsapp_channel.inbox.conversations).to be_empty
      end

      it 'processes an ordinary message delivered in the same batch as the system event' do
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
        value = system_message_params[:entry][0][:changes][0][:value]
        value[:contacts] = [{ profile: { name: 'Rotated customer' }, user_id: 'IN.CURRENTBSUID' }]
        value[:messages].prepend(
          {
            from_user_id: 'IN.CURRENTBSUID', id: 'wamid.ORDINARY_MESSAGE_ID', timestamp: '1664799905',
            type: 'text', text: { body: 'Message delivered with the lifecycle event' }
          }
        )

        rotate

        expect(whatsapp_channel.inbox.messages.last.content).to eq('Message delivered with the lifecycle event')
        expect(whatsapp_channel.inbox.messages.last.conversation.contact).to eq(contact)
        expect(whatsapp_channel.inbox.contact_inboxes.find_by(source_id: 'IN.CURRENTBSUID').contact).to eq(contact)
      end

      it 'updates the contact phone and records the phone alias for a number change' do
        previous = create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
        previous.contact.update!(phone_number: '+16505550001')
        system.merge!(type: 'user_changed_number', wa_id: '16505550002')

        rotate

        expect(previous.contact.reload.phone_number).to eq('+16505550002')
        expect(whatsapp_channel.inbox.contact_inboxes.find_by(source_id: '16505550002').contact).to eq(previous.contact)
      end

      it 'keeps conflicting aliases on separate contacts' do
        previous = create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
        current = create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: create(:contact, account: whatsapp_channel.inbox.account),
                                         source_id: 'IN.CURRENTBSUID')

        rotate

        expect(previous.reload.contact_id).not_to eq(current.reload.contact_id)
      end

      it 'is idempotent when the same system event is delivered again' do
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
        rotate

        expect { rotate }.not_to change(ContactInbox, :count)
      end

      it 'does nothing when neither the previous nor current identifier is known' do
        expect { rotate }.not_to change(ContactInbox, :count)
      end
    end
  end

  # Métodos auxiliares para reduzir o tamanho do exemplo

  def stub_media_url_request
    stub_request(
      :get,
      whatsapp_channel.media_url('b1c68f38-8734-4ad3-b4a1-ef0c10d683')
    ).to_return(
      status: 200,
      body: {
        messaging_product: 'whatsapp',
        url: 'https://chatwoot-assets.local/sample.png',
        mime_type: 'image/jpeg',
        sha256: 'sha256',
        file_size: 'SIZE',
        id: 'b1c68f38-8734-4ad3-b4a1-ef0c10d683'
      }.to_json,
      headers: { 'content-type' => 'application/json' }
    )
  end

  def stub_sample_png_request
    stub_request(:get, 'https://chatwoot-assets.local/sample.png').to_return(
      status: 200,
      body: File.read('spec/assets/sample.png')
    )
  end

  def expect_conversation_created
    expect(whatsapp_channel.inbox.conversations.count).not_to eq(0)
  end

  def expect_contact_name
    expect(contact_from_number&.name).to eq('Sojan Jose')
  end

  def expect_message_content
    expect(whatsapp_channel.inbox.messages.first.content).to eq('Check out my product!')
  end

  def expect_message_has_attachment
    expect(whatsapp_channel.inbox.messages.first.attachments.present?).to be true
  end

  def contact_phone_number
    "+#{sender_number}"
  end

  def contact_from_number
    Contact.find_by(phone_number: contact_phone_number)
  end
end
