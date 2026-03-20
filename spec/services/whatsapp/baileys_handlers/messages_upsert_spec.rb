require 'rails_helper'

describe Whatsapp::BaileysHandlers::MessagesUpsert do
  let(:webhook_verify_token) { 'valid_token' }
  let!(:whatsapp_channel) do
    create(:channel_whatsapp,
           provider: 'baileys',
           provider_config: { webhook_verify_token: webhook_verify_token },
           validate_provider_config: false,
           received_messages: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:timestamp) { Time.current.to_i }

  before do
    stub_request(:get, /profile-picture-url/)
      .to_return(
        status: 200,
        body: { data: { profilePictureUrl: nil } }.to_json
      )
  end

  describe '#update_existing_contact_inbox' do
    context 'when updating contact inbox with LID information' do
      let(:phone) { '5511912345678' }
      let(:lid) { '12345678' }
      let(:source_id) { lid }
      let(:identifier) { "#{lid}@lid" }

      context 'when there is no conflict' do
        it 'updates existing contact_inbox source_id from phone to LID' do
          contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: nil)
          contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone)

          raw_message = {
            key: { id: 'msg_123', remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: false, addressingMode: 'lid' },
            pushName: 'John Doe',
            messageTimestamp: timestamp,
            message: { conversation: 'Hello' }
          }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: { type: 'notify', messages: [raw_message] }
          }

          expect do
            Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
          end.not_to raise_error

          expect(contact_inbox.reload.source_id).to eq(source_id)
          expect(contact.reload.identifier).to eq(identifier)
          expect(contact.phone_number).to eq("+#{phone}")
        end
      end

      context 'when identifier is already taken by a different contact (race condition)' do
        it 'consolidates contacts and saves message on the canonical contact' do
          original_contact = create(:contact, account: inbox.account, phone_number: nil, identifier: nil, name: 'Original Contact')
          original_contact_inbox = create(:contact_inbox, inbox: inbox, contact: original_contact, source_id: phone)

          conflicting_contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: identifier,
                                                 name: 'Conflicting Contact')
          create(:contact_inbox, inbox: inbox, contact: conflicting_contact, source_id: source_id)

          raw_message = {
            key: { id: 'msg_123', remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: false, addressingMode: 'lid' },
            pushName: 'John Doe',
            messageTimestamp: timestamp,
            message: { conversation: 'Hello' }
          }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: { type: 'notify', messages: [raw_message] }
          }

          expect do
            Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
          end.not_to raise_error

          # Consolidation merges into original_contact (phone contact_inbox's contact)
          expect(original_contact_inbox.reload.source_id).to eq(source_id)
          expect(original_contact.reload.identifier).to eq(identifier)
          expect(original_contact.phone_number).to eq("+#{phone}")

          message = inbox.messages.last
          expect(message).to be_present
          expect(message.sender).to eq(original_contact)
          expect(message.conversation.contact).to eq(original_contact)
        end
      end

      context 'when phone number is already taken by a different contact (race condition)' do
        it 'does not raise validation error and skips the update' do
          original_contact = create(:contact, account: inbox.account, phone_number: nil, identifier: nil)
          create(:contact_inbox, inbox: inbox, contact: original_contact, source_id: phone)

          different_lid = '87654321'
          different_identifier = "#{different_lid}@lid"
          conflicting_contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: different_identifier)
          create(:contact_inbox, inbox: inbox, contact: conflicting_contact, source_id: different_lid)

          raw_message = {
            key: { id: 'msg_123', remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: false, addressingMode: 'lid' },
            pushName: 'John Doe',
            messageTimestamp: timestamp,
            message: { conversation: 'Hello' }
          }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: { type: 'notify', messages: [raw_message] }
          }

          expect do
            Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
          end.not_to raise_error

          expect(original_contact.reload.phone_number).to be_nil
          expect(original_contact.identifier).to be_nil
        end
      end

      context 'when LID contact_inbox already exists (race condition)' do
        it 'consolidates contacts and saves message on the canonical contact' do
          original_contact = create(:contact, account: inbox.account, phone_number: nil, identifier: nil)
          original_contact_inbox = create(:contact_inbox, inbox: inbox, contact: original_contact, source_id: phone)

          lid_contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: identifier)
          create(:contact_inbox, inbox: inbox, contact: lid_contact, source_id: source_id)

          raw_message = {
            key: { id: 'msg_123', remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: false, addressingMode: 'lid' },
            pushName: 'John Doe',
            messageTimestamp: timestamp,
            message: { conversation: 'Hello' }
          }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: { type: 'notify', messages: [raw_message] }
          }

          expect do
            Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
          end.not_to raise_error

          # Consolidation merges into original_contact (phone contact_inbox's contact)
          expect(original_contact_inbox.reload.source_id).to eq(source_id)
          expect(original_contact.reload.identifier).to eq(identifier)
          expect(original_contact.phone_number).to eq("+#{phone}")

          message = inbox.messages.last
          expect(message).to be_present
          expect(message.sender).to eq(original_contact)
        end
      end

      context 'when updating the same contact (no conflict)' do
        it 'successfully updates the contact' do
          contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: nil)
          contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone)

          raw_message = {
            key: { id: 'msg_123', remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: false, addressingMode: 'lid' },
            pushName: 'John Doe',
            messageTimestamp: timestamp,
            message: { conversation: 'Hello' }
          }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: { type: 'notify', messages: [raw_message] }
          }

          expect do
            Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
          end.not_to raise_error

          expect(contact_inbox.reload.source_id).to eq(source_id)
          expect(contact.reload.identifier).to eq(identifier)
          expect(contact.phone_number).to eq("+#{phone}")
        end
      end
    end
  end

  describe 'fragmented contacts: phone vs LID with different contact_ids' do
    let(:phone) { '19543717011' }
    let(:lid) { '116883390996710' }
    let(:identifier) { "#{lid}@lid" }

    context 'when phone-based and LID-based contact_inboxes belong to different contacts' do
      it 'still saves the incoming message without raising' do
        # Setup: two separate contacts for the same WhatsApp user (fragmented identity)
        phone_contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: nil, name: 'Brigita Pinto')
        create(:contact_inbox, inbox: inbox, contact: phone_contact, source_id: phone)

        lid_contact = create(:contact, account: inbox.account, phone_number: nil, identifier: identifier, name: lid)
        create(:contact_inbox, inbox: inbox, contact: lid_contact, source_id: lid)

        raw_message = {
          key: { id: 'msg_fragmented_001', remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: false,
                 addressingMode: 'lid' },
          pushName: 'Brigita Pinto',
          messageTimestamp: timestamp,
          message: { conversation: 'Queria agendar a reunião' }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        # This scenario previously caused a uniqueness violation when update_contact_info
        # tried to set phone_number on the LID contact. The consolidation service now handles this.
        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.not_to raise_error

        message = inbox.messages.find_by(source_id: 'msg_fragmented_001')
        expect(message).to be_present
        expect(message.content).to eq('Queria agendar a reunião')
        expect(message.message_type).to eq('incoming')
      end
    end
  end

  describe 'ephemeral message handling' do
    let(:phone) { '5511912345678' }
    let(:lid) { '12345678' }

    context 'when receiving an ephemeral text message' do
      it 'correctly unwraps and processes the message' do
        raw_message = {
          key: { id: 'msg_ephemeral_123', remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false,
                 addressingMode: 'pn' },
          pushName: 'Gabriel',
          messageTimestamp: timestamp,
          message: {
            messageContextInfo: {
              deviceListMetadata: {},
              deviceListMetadataVersion: 2
            },
            ephemeralMessage: {
              message: {
                extendedTextMessage: {
                  text: 'This is a disappearing message',
                  contextInfo: {
                    expiration: 604_800,
                    disappearingMode: { initiator: 0 }
                  }
                }
              }
            }
          }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.content).to eq('This is a disappearing message')
        expect(message.message_type).to eq('incoming')
        expect(message.is_unsupported).to be_falsey
      end
    end

    context 'when receiving an ephemeral image message' do
      it 'correctly unwraps and processes the message with media' do
        raw_message = {
          key: { id: 'msg_ephemeral_image_123', remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false,
                 addressingMode: 'pn' },
          pushName: 'Gabriel',
          messageTimestamp: timestamp,
          message: {
            messageContextInfo: {
              deviceListMetadata: {},
              deviceListMetadataVersion: 2
            },
            ephemeralMessage: {
              message: {
                imageMessage: {
                  caption: 'Check this out',
                  mimetype: 'image/jpeg',
                  url: 'https://example.com/image.jpg'
                }
              }
            }
          }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        stub_request(:get, whatsapp_channel.media_url('msg_ephemeral_image_123'))
          .to_return(status: 200, body: 'fake image data')

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.content).to eq('Check this out')
        expect(message.message_type).to eq('incoming')
        expect(message.is_unsupported).to be_falsey
        expect(message.attachments.count).to eq(1)
      end
    end

    context 'when receiving an ephemeral reaction message' do
      it 'correctly unwraps and processes the reaction' do
        # First create the original message
        contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: "#{lid}@lid")
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid)
        conversation = create(:conversation, inbox: inbox, contact_inbox: contact_inbox)
        original_message = create(:message, inbox: inbox, conversation: conversation, source_id: 'original_msg_id')

        raw_message = {
          key: { id: 'msg_ephemeral_reaction_123', remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false,
                 addressingMode: 'pn' },
          pushName: 'Gabriel',
          messageTimestamp: timestamp,
          message: {
            messageContextInfo: {
              deviceListMetadata: {},
              deviceListMetadataVersion: 2
            },
            ephemeralMessage: {
              message: {
                reactionMessage: {
                  text: '👍',
                  key: { id: 'original_msg_id' }
                }
              }
            }
          }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(conversation.messages, :count).by(1)

        reaction = conversation.messages.last
        expect(reaction.content).to eq('👍')
        expect(reaction.message_type).to eq('incoming')
        expect(reaction.content_attributes['is_reaction']).to be_truthy
        expect(reaction.in_reply_to).to eq(original_message.id)
        expect(reaction.in_reply_to_external_id).to eq(original_message.source_id)
      end
    end
  end

  describe 'filename extraction' do
    let(:phone) { '5511912345678' }

    before do
      %w[msg_doc_1 msg_doc_2 msg_image_1 msg_audio_1].each do |message_id|
        stub_request(:get, whatsapp_channel.media_url(message_id))
          .to_return(status: 200, body: 'fake content')
      end
    end

    context 'when receiving a document message with filename' do
      it 'extracts the filename correctly' do
        raw_message = {
          key: { id: 'msg_doc_1', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false },
          pushName: 'User',
          messageTimestamp: timestamp,
          message: {
            documentMessage: {
              url: 'https://example.com/doc.pdf',
              mimetype: 'application/pdf',
              fileName: 'contract.pdf'
            }
          }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        attachment = message.attachments.first
        expect(attachment.file.filename.to_s).to eq('contract.pdf')
      end
    end

    context 'when receiving a document with caption message with filename' do
      it 'extracts the filename correctly' do
        raw_message = {
          key: { id: 'msg_doc_2', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false },
          pushName: 'User',
          messageTimestamp: timestamp,
          message: {
            documentWithCaptionMessage: {
              message: {
                documentMessage: {
                  url: 'https://example.com/doc.pdf',
                  mimetype: 'application/pdf',
                  fileName: 'report.pdf'
                }
              }
            }
          }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        attachment = message.attachments.first
        expect(attachment.file.filename.to_s).to eq('report.pdf')
      end
    end

    context 'when filename is missing' do
      it 'generates a filename based on mimetype' do
        raw_message = {
          key: { id: 'msg_image_1', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false },
          pushName: 'User',
          messageTimestamp: timestamp,
          message: {
            imageMessage: {
              url: 'https://example.com/image.jpg',
              mimetype: 'image/jpeg'
            }
          }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        attachment = message.attachments.first
        expect(attachment.file.filename.to_s).to match(/image_msg_image_1_\d{8}\.jpeg/)
      end
    end

    context 'when filename is missing and mimetype has extra parameters' do
      it 'generates a filename based on mimetype correctly' do
        raw_message = {
          key: { id: 'msg_audio_1', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false },
          pushName: 'User',
          messageTimestamp: timestamp,
          message: {
            audioMessage: {
              url: 'https://example.com/audio.ogg',
              mimetype: 'audio/ogg; codecs=opus'
            }
          }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        attachment = message.attachments.first
        expect(attachment.file.filename.to_s).to match(/audio_msg_audio_1_\d{8}\.ogg/)
      end
    end
  end

  describe 'group message handling' do
    before do
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:groups_enabled?).and_return(true)
    end

    let(:group_jid) { '123456789123456789@g.us' }
    let(:group_source_id) { '123456789123456789' }
    let(:sender_phone) { '5511912345678' }
    let(:sender_lid) { '12345678' }

    def build_group_raw_message(id:, text:, sender_participant: "#{sender_lid}@lid", sender_alt: "#{sender_phone}@s.whatsapp.net")
      {
        key: { id: id, remoteJid: group_jid, participant: sender_participant, participantAlt: sender_alt, fromMe: false },
        pushName: 'Sender User',
        messageTimestamp: timestamp,
        message: { conversation: text }
      }
    end

    def build_params(raw_message)
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'notify', messages: [raw_message] } }
    end

    it 'creates a group conversation where the message sender is a group member' do
      params = build_params(build_group_raw_message(id: 'grp_msg_001', text: 'Hello group'))

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
      end.to change(inbox.messages, :count).by(1)
         .and change(Conversation, :count).by(1)

      message = inbox.messages.last
      conversation = message.conversation
      group_contact = conversation.contact

      expect(group_contact.group_type).to eq('group')
      expect(group_contact.identifier).to eq(group_jid)
      expect(conversation.group_type).to eq('group')
      expect(message.content).to eq('Hello group')
      expect(message.sender).not_to eq(group_contact)
      expect(GroupMember.where(group_contact: group_contact).active.pluck(:contact_id)).to include(message.sender_id)
    end

    it 'adds only the message sender as a group member' do
      params = build_params(build_group_raw_message(id: 'grp_msg_002', text: 'Hi'))

      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

      conversation = inbox.conversations.last
      group_contact = conversation.contact
      members = GroupMember.where(group_contact: group_contact).active

      expect(members.count).to eq(1)
      sender_member = members.first
      expect(sender_member.contact.phone_number).to eq("+#{sender_phone}")
      expect(sender_member.role).to eq('member')
    end

    it 'creates message with correct sender when different members send messages' do
      other_phone = '5511911111111'
      other_lid = '11111111'

      Whatsapp::IncomingMessageBaileysService.new(
        inbox: inbox,
        params: build_params(build_group_raw_message(id: 'grp_msg_005', text: 'From sender'))
      ).perform

      Whatsapp::IncomingMessageBaileysService.new(
        inbox: inbox,
        params: build_params(build_group_raw_message(
                               id: 'grp_msg_006', text: 'From other',
                               sender_participant: "#{other_lid}@lid", sender_alt: "#{other_phone}@s.whatsapp.net"
                             ))
      ).perform

      conversation = inbox.conversations.last
      messages = conversation.messages.order(:created_at)

      expect(messages.first.sender.phone_number).to eq("+#{sender_phone}")
      expect(messages.last.sender.phone_number).to eq("+#{other_phone}")
      expect(messages.first.sender).not_to eq(messages.last.sender)
      expect(conversation.contact.group_type).to eq('group')
    end

    it 'processes a group image message with attachment' do
      stub_request(:get, whatsapp_channel.media_url('grp_img_001'))
        .to_return(status: 200, body: 'fake image data')

      raw_message = {
        key: { id: 'grp_img_001', remoteJid: group_jid, participant: "#{sender_lid}@lid",
               participantAlt: "#{sender_phone}@s.whatsapp.net", fromMe: false },
        pushName: 'Sender User',
        messageTimestamp: timestamp,
        message: { imageMessage: { caption: 'Group photo', mimetype: 'image/jpeg', url: 'https://example.com/img.jpg' } }
      }
      params = build_params(raw_message)

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
      end.to change(inbox.messages, :count).by(1)

      message = inbox.messages.last

      expect(message.content).to eq('Group photo')
      expect(message.attachments.count).to eq(1)
      expect(message.sender).not_to eq(message.conversation.contact)
    end
  end

  describe 'conversation duplication after deletion or resolution' do
    let(:phone) { '5511912345678' }
    let(:lid) { '12345678' }

    def build_raw_message(id:, text:)
      {
        key: { id: id, remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: false, addressingMode: 'lid' },
        pushName: 'John Doe',
        messageTimestamp: timestamp,
        message: { conversation: text }
      }
    end

    def build_params(raw_message)
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'notify', messages: [raw_message] } }
    end

    shared_examples 'routes messages to the new conversation' do |first_msg_id:, second_msg_id:|
      it 'routes incoming messages to the new conversation, not a third one' do
        # Step 1: Create contact and first contact_inbox with phone as source_id
        contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: nil)
        first_contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone)
        first_conversation = create(:conversation, inbox: inbox, contact: contact, contact_inbox: first_contact_inbox)

        # Step 2: Contact responds - this updates contact_inbox source_id from phone to LID
        Whatsapp::IncomingMessageBaileysService.new(
          inbox: inbox,
          params: build_params(build_raw_message(id: first_msg_id, text: 'First response'))
        ).perform

        # Verify message landed in first conversation and source_id migrated
        expect(first_conversation.messages.count).to eq(1)
        expect(first_contact_inbox.reload.source_id).to eq(lid)

        # Step 3: Either delete or resolve the first conversation
        close_first_conversation.call(first_conversation)

        # Step 4: Create a new conversation (simulating UI creating a new contact_inbox)
        second_contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone)
        second_conversation = create(:conversation, inbox: inbox, contact: contact, contact_inbox: second_contact_inbox, status: :open)
        expect(inbox.contact_inboxes.where(contact: contact).count).to eq(2)

        # Step 5: Contact responds again - should NOT create a third conversation
        expect do
          Whatsapp::IncomingMessageBaileysService.new(
            inbox: inbox,
            params: build_params(build_raw_message(id: second_msg_id, text: 'Second response'))
          ).perform
        end.not_to change(Conversation, :count)

        # The message should arrive in the second conversation
        expect(second_conversation.reload.messages.last.content).to eq('Second response')

        # The duplicate contact_inboxes should be consolidated
        expect(inbox.contact_inboxes.where(contact: contact).count).to eq(1)
      end
    end

    context 'when a conversation is deleted and a new one is created for the same contact' do
      let(:close_first_conversation) { ->(conv) { conv.destroy! } }

      it_behaves_like 'routes messages to the new conversation', first_msg_id: 'msg_001', second_msg_id: 'msg_002'
    end

    context 'when a conversation is resolved and a new one is created for the same contact' do
      let(:close_first_conversation) { ->(conv) { conv.update!(status: :resolved) } }

      it_behaves_like 'routes messages to the new conversation', first_msg_id: 'msg_003', second_msg_id: 'msg_004'
    end
  end

  describe 'membership request stub handling' do
    let(:group_jid) { '123456789123456789@g.us' }
    let(:requester_lid) { '12345678' }
    let(:requester_phone) { '5511912345678' }
    let(:participant_json) { { lid: "#{requester_lid}@lid", pn: "#{requester_phone}@s.whatsapp.net" }.to_json }

    def build_stub_message(action_params)
      {
        key: { remoteJid: group_jid, fromMe: false, id: '11111111', participant: "#{requester_lid}@lid" },
        messageTimestamp: { low: timestamp, high: 0, unsigned: true },
        participant: "#{requester_lid}@lid",
        messageStubType: 'GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD',
        messageStubParameters: [participant_json, *action_params]
      }
    end

    def build_params(raw_message)
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'append', messages: [raw_message] } }
    end

    def perform_service(raw_message)
      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: build_params(raw_message)).perform
    end

    context 'when a user requests to join the group' do
      let(:raw_message) { build_stub_message(%w[created invite_link]) }

      it 'creates an activity message indicating the user wants to join' do
        expect { perform_service(raw_message) }
          .to change(inbox.messages, :count).by(1)
          .and change(Conversation, :count).by(1)

        message = inbox.messages.last

        expect(message.message_type).to eq('activity')
        expect(message.content).to include('wants to join the group')
      end
    end

    context 'when a user revokes their join request' do
      let(:raw_message) { build_stub_message(%w[revoked]) }

      it 'creates an activity message indicating the user no longer wants to join' do
        expect { perform_service(raw_message) }
          .to change(inbox.messages, :count).by(1)

        message = inbox.messages.last

        expect(message.message_type).to eq('activity')
        expect(message.content).to include('no longer wants to join the group')
      end
    end
  end

  describe 'group icon change stub handling' do
    let(:group_jid) { '123456789123456789@g.us' }
    let(:raw_message) do
      {
        key: { remoteJid: group_jid, fromMe: false, id: '111111111', participant: "#{author_lid}@lid" },
        messageTimestamp: timestamp.to_s,
        participant: "#{author_lid}@lid",
        messageStubType: 'GROUP_CHANGE_ICON',
        messageStubParameters: [timestamp.to_s]
      }
    end
    let(:author_lid) { '12345678' }

    def build_params(raw_message)
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'append', messages: [raw_message] } }
    end

    def perform_service(raw_message)
      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: build_params(raw_message)).perform
    end

    it 'creates an activity message about the icon change' do
      expect { perform_service(raw_message) }
        .to change(inbox.messages, :count).by(1)
        .and change(Conversation, :count).by(1)

      message = inbox.messages.last

      expect(message.message_type).to eq('activity')
      expect(message.content).to include('changed the group image')
    end
  end

  describe 'unhandled stub messages' do
    let(:group_jid) { '123456789123456789@g.us' }

    def build_params(raw_message)
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'append', messages: [raw_message] } }
    end

    it 'does not crash and silently ignores unhandled group stub types' do
      raw_message = {
        key: { remoteJid: group_jid, fromMe: false, id: '11111111', participant: '12345678@lid' },
        messageTimestamp: Time.current.to_i.to_s,
        participant: '12345678@lid',
        messageStubType: 'SOME_STUB_TYPE_WE_DONT_CARE_ABOUT'
      }

      expect { Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: build_params(raw_message)).perform }
        .not_to raise_error
    end
  end
end
