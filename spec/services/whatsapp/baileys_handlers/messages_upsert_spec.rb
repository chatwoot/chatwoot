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

      context 'when phone contact has contact_inbox with phone source_id and a separate LID contact exists (provider conversion)' do
        it 'resolves the identifier conflict and uses the phone contact' do
          phone_contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: nil, name: 'Phone Contact')
          phone_ci = create(:contact_inbox, inbox: inbox, contact: phone_contact, source_id: phone)
          create(:contact, account: inbox.account, identifier: identifier, phone_number: nil, name: 'LID Contact')

          raw_message = {
            key: { id: 'msg_conv_123', remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: false,
                   addressingMode: 'lid' },
            pushName: 'Phone Contact',
            messageTimestamp: timestamp,
            message: { conversation: 'Hello after conversion' }
          }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: { type: 'notify', messages: [raw_message] }
          }

          expect do
            Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
          end.not_to raise_error

          expect(phone_ci.reload.source_id).to eq(source_id)
          expect(phone_contact.reload.identifier).to eq(identifier)
          expect(phone_contact.phone_number).to eq("+#{phone}")

          message = inbox.messages.find_by(source_id: 'msg_conv_123')
          expect(message).to be_present
          expect(message.sender).to eq(phone_contact)
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

  describe 'album and wrapped media handling' do
    let(:phone) { '5511912345678' }
    let(:lid) { '12345678' }

    context 'when receiving an album marker message' do
      it 'ignores the marker and creates no message' do
        raw_message = {
          key: { id: 'msg_album_marker', remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false,
                 addressingMode: 'pn' },
          pushName: 'Gabriel',
          messageTimestamp: timestamp,
          message: {
            messageContextInfo: {
              deviceListMetadata: {},
              deviceListMetadataVersion: 2
            },
            albumMessage: { expectedImageCount: 2, expectedVideoCount: 0 }
          }
        }
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: { type: 'notify', messages: [raw_message] }
        }

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.not_to change(Message, :count)
      end
    end

    # WhatsApp stopped sending message edits as a plaintext protocolMessage and
    # now encrypts them under the original message's secret. Only the provider
    # can decrypt one, and it delivers the result as a messages.update; a blob
    # that still reaches here has no key and rendering it told the agent the
    # contact had sent an unsupported message.
    context 'when receiving an encrypted message edit the provider could not decrypt' do
      it 'ignores it and creates no message' do
        raw_message = {
          key: { id: 'msg_secret_edit', remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false,
                 addressingMode: 'pn' },
          pushName: 'Gabriel',
          messageTimestamp: timestamp,
          message: {
            messageContextInfo: { deviceListMetadata: {}, deviceListMetadataVersion: 2 },
            secretEncryptedMessage: {
              targetMessageKey: { id: 'msg_original', remoteJid: "#{lid}@lid", fromMe: true },
              encPayload: 'ZW5jcnlwdGVk',
              encIv: 'aXY=',
              secretEncType: 2
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
        end.not_to change(Message, :count)
      end
    end

    context 'when receiving an album child image message' do
      it 'unwraps the wrapper and processes the message with media' do
        raw_message = {
          key: { id: 'msg_album_child_1', remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false,
                 addressingMode: 'pn' },
          pushName: 'Gabriel',
          messageTimestamp: timestamp,
          message: {
            messageContextInfo: {
              deviceListMetadata: {},
              deviceListMetadataVersion: 2
            },
            associatedChildMessage: {
              message: {
                imageMessage: {
                  caption: 'Album photo',
                  mimetype: 'image/jpeg',
                  url: 'https://example.com/img.jpg'
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

        stub_request(:get, whatsapp_channel.media_url('msg_album_child_1'))
          .to_return(status: 200, body: 'fake image data')

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.content).to eq('Album photo')
        expect(message.is_unsupported).to be_falsey
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('image')
      end
    end

    context 'when receiving an album child nested inside an ephemeral message' do
      it 'unwraps the nested wrappers and processes the message with media' do
        raw_message = {
          key: { id: 'msg_nested_wrappers_1', remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false,
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
                associatedChildMessage: {
                  message: {
                    imageMessage: {
                      caption: 'Nested album photo',
                      mimetype: 'image/jpeg',
                      url: 'https://example.com/nested.jpg'
                    }
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

        stub_request(:get, whatsapp_channel.media_url('msg_nested_wrappers_1'))
          .to_return(status: 200, body: 'fake image data')

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.content).to eq('Nested album photo')
        expect(message.is_unsupported).to be_falsey
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('image')
      end
    end

    context 'when receiving a lottie sticker message' do
      it 'unwraps the wrapper and processes the sticker with media' do
        raw_message = {
          key: { id: 'msg_lottie_1', remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false,
                 addressingMode: 'pn' },
          pushName: 'Gabriel',
          messageTimestamp: timestamp,
          message: {
            messageContextInfo: {
              deviceListMetadata: {},
              deviceListMetadataVersion: 2,
              messageSecret: 'secret'
            },
            lottieStickerMessage: {
              message: {
                stickerMessage: {
                  mimetype: 'application/was',
                  url: 'https://example.com/sticker.was',
                  isLottie: true
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

        stub_request(:get, whatsapp_channel.media_url('msg_lottie_1'))
          .to_return(status: 200, body: 'fake sticker data')

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.is_unsupported).to be_falsey
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('image')
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

    # The mirror of the shape above: a phone-addressed group carries the author's phone in
    # `participant` and their LID in `participantAlt`. Reading the alt as a phone number
    # because it is digits put the LID in the contact's phone field and left the LID field
    # empty, swapping the two.
    it 'reads the author of a phone-addressed group by the address that is a phone number' do
      params = build_params(
        build_group_raw_message(
          id: 'grp_pn_001',
          text: 'Hello from a phone-addressed group',
          sender_participant: "#{sender_phone}@s.whatsapp.net",
          sender_alt: "#{sender_lid}@lid"
        )
      )

      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

      sender = inbox.messages.find_by(source_id: 'grp_pn_001').sender
      expect(sender.phone_number).to eq("+#{sender_phone}")
      expect(sender.identifier).to eq("#{sender_lid}@lid")
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

    it 'anchors a group reaction to the target message conversation when it is resolved instead of opening a new one' do
      Whatsapp::IncomingMessageBaileysService.new(
        inbox: inbox,
        params: build_params(build_group_raw_message(id: 'grp_target_001', text: 'Original group message'))
      ).perform

      conversation = inbox.conversations.last
      target_message = conversation.messages.last
      conversation.update!(status: :resolved)

      reaction_raw = {
        key: { id: 'grp_reaction_001', remoteJid: group_jid, participant: "#{sender_lid}@lid",
               participantAlt: "#{sender_phone}@s.whatsapp.net", fromMe: false },
        pushName: 'Sender User',
        messageTimestamp: timestamp,
        message: { reactionMessage: { key: { id: target_message.source_id }, text: '👍' } }
      }

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: build_params(reaction_raw)).perform
      end.not_to change(Conversation, :count)

      reaction = conversation.reload.messages.last
      expect(reaction.is_reaction).to be(true)
      expect(reaction.conversation_id).to eq(conversation.id)
      expect(reaction.in_reply_to_external_id).to eq(target_message.source_id)
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

  describe 'echo of a message sent by Chatwoot' do
    let(:phone) { '5511912345678' }
    let(:lid) { '12345678' }
    let(:contact) { create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: "#{lid}@lid") }
    let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid) }
    let(:conversation) { create(:conversation, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

    def echo_params(id)
      raw_message = {
        key: { id: id, remoteJid: "#{lid}@lid", remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: true, addressingMode: 'lid' },
        messageTimestamp: timestamp,
        message: { conversation: '*John* olá' }
      }
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'append', messages: [raw_message] } }
    end

    # The send response never arrived, so `source_id` is still blank and only the id reserved before
    # the request identifies the message. Without that match the echo would land as a second message
    # attributed to WhatsApp instead of the agent.
    it 'confirms the reserved message instead of creating a duplicate' do
      sent = create(:message, inbox: inbox, conversation: conversation, message_type: :outgoing,
                              content: '**John** olá', source_id: nil,
                              content_attributes: { pending_source_id: 'RESERVED_1' })

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: echo_params('RESERVED_1')).perform
      end.not_to change(Message, :count)

      expect(sent.reload.source_id).to eq('RESERVED_1')
    end

    # A delayed echo must not reopen the thread it belongs to, nor open a new one to hold a message
    # that is already stored.
    it 'confirms a reserved message whose conversation was resolved meanwhile' do
      sent = create(:message, inbox: inbox, conversation: conversation, message_type: :outgoing,
                              content: '**John** olá', source_id: nil,
                              content_attributes: { pending_source_id: 'RESERVED_3' })
      conversation.update!(status: :resolved)

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: echo_params('RESERVED_3')).perform
      end.to not_change(Message, :count).and not_change(Conversation, :count)

      expect(sent.reload.source_id).to eq('RESERVED_3')
      expect(conversation.reload.status).to eq('resolved')
    end

    # Deleting a message whose send is still in flight leaves nobody holding its provider id, so the
    # echo is the only chance to learn it — and to revoke the message on the contact's phone.
    it 'revokes on the channel when the confirmed message was deleted meanwhile' do
      sent = create(:message, inbox: inbox, conversation: conversation, message_type: :outgoing,
                              content: 'Mensagem apagada', source_id: nil,
                              content_attributes: { pending_source_id: 'RESERVED_4', deleted: true })

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: echo_params('RESERVED_4')).perform
      end.to have_enqueued_job(Messages::DeleteOnChannelJob).with(sent.id)

      expect(sent.reload.source_id).to eq('RESERVED_4')
    end

    # The retries ran out before this echo arrived, so the message was marked failed. The
    # echo proves it reached WhatsApp, and leaving it failed puts a Retry button on it —
    # Retry clears the reservation and sends a fresh id, which is the duplicate the
    # reservation exists to prevent.
    it 'retires the send failure of a message the echo proves arrived' do
      sent = create(:message, inbox: inbox, conversation: conversation, message_type: :outgoing,
                              content: '**John** olá', source_id: nil, status: :failed,
                              external_error: 'send timed out',
                              content_attributes: { pending_source_id: 'RESERVED_5' })

      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: echo_params('RESERVED_5')).perform

      expect(sent.reload.source_id).to eq('RESERVED_5')
      expect(sent.status).to eq('sent')
      expect(sent.external_error).to be_blank
    end

    it 'keeps the source_id already confirmed by the send response' do
      sent = create(:message, inbox: inbox, conversation: conversation, message_type: :outgoing,
                              content: '**John** olá', source_id: 'RESERVED_2',
                              content_attributes: { pending_source_id: 'RESERVED_2' })

      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: echo_params('RESERVED_2')).perform

      expect(sent.reload.source_id).to eq('RESERVED_2')
    end

    it 'still stores a message actually sent from the phone' do
      conversation

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: echo_params('PHONE_MSG_1')).perform
      end.to change(Message, :count).by(1)

      message = Message.find_by(source_id: 'PHONE_MSG_1')
      expect(message).to be_outgoing
      expect(message.sender).to be_nil
      expect(message.content_attributes['external_sender_name']).to eq('WhatsApp')
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

  describe 'click-to-WhatsApp ad referral and entry-point handling' do
    let(:phone) { '5511912345678' }
    let(:external_ad_reply) do
      {
        title: 'Promo de Inverno',
        body: '50% OFF em tudo',
        mediaType: 'IMAGE',
        thumbnailUrl: 'https://example.com/ad-thumb.jpg',
        sourceType: 'ad',
        sourceId: '120210000000000',
        sourceUrl: 'https://fb.me/abc123',
        ctwaClid: 'ARAaCtwaClid123'
      }
    end
    let(:lid) { '12345678' }

    # Scope the dedupe cleanup to this inbox so it can't wipe keys other specs
    # are using against the same Redis DB.
    after do
      Redis::Alfred.scan_each(match: "MESSAGE_SOURCE_KEY::#{inbox.id}_*") { |key| Redis::Alfred.delete(key) }
    end

    # Each example needs a distinct id so the MESSAGE_SOURCE_KEY dedupe doesn't
    # short-circuit later examples based on execution order.
    def ad_params(message, id:)
      raw_message = {
        key: { id: id, remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false, addressingMode: 'pn' },
        pushName: 'Lead Anúncio',
        messageTimestamp: timestamp,
        message: message
      }
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'notify', messages: [raw_message] } }
    end

    context 'when a text message carries an externalAdReply' do
      it 'persists the referral on the message and the conversation' do
        params = ad_params(
          { extendedTextMessage: { text: 'Oi, vi o anúncio', contextInfo: { externalAdReply: external_ad_reply } } },
          id: 'ad_msg_text_1'
        )

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.content).to eq('Oi, vi o anúncio')
        expect(message.content_attributes['referral']).to include(
          'source_type' => 'ad', 'source_id' => '120210000000000', 'source_url' => 'https://fb.me/abc123',
          'ctwa_clid' => 'ARAaCtwaClid123', 'title' => 'Promo de Inverno', 'body' => '50% OFF em tudo',
          'media_type' => 'image', 'thumbnail_url' => 'https://example.com/ad-thumb.jpg'
        )
        expect(message.conversation.additional_attributes['referral']).to include('ctwa_clid' => 'ARAaCtwaClid123')
      end
    end

    context 'when an ad-click message has no text body' do
      it 'still creates a renderable message using the ad headline as content' do
        params = ad_params(
          { extendedTextMessage: { contextInfo: { externalAdReply: external_ad_reply } } },
          id: 'ad_msg_headline_fallback_1'
        )

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.is_unsupported).to be_falsey
        expect(message.content).to eq('Promo de Inverno')
        expect(message.content_attributes['referral']).to include('ctwa_clid' => 'ARAaCtwaClid123')
      end
    end

    context 'when externalAdReply mediaType is the numeric proto enum' do
      it 'maps the enum number to the string media type' do
        ad = external_ad_reply.merge(mediaType: 2)
        params = ad_params(
          { extendedTextMessage: { text: 'oi', contextInfo: { externalAdReply: ad } } },
          id: 'ad_msg_numeric_media_1'
        )

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content_attributes.dig('referral', 'media_type')).to eq('video')
      end
    end

    context 'when the message comes from a click-to-chat link (no ad)' do
      it 'records the entry point on the conversation without a referral or card' do
        params = ad_params(
          { extendedTextMessage: {
            text: 'oi',
            contextInfo: { entryPointConversionSource: 'click_to_chat_link', entryPointConversionApp: '' }
          } },
          id: 'ad_msg_entry_point_1'
        )

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.content).to eq('oi')
        expect(message.content_attributes['referral']).to be_nil
        expect(message.conversation.additional_attributes['referral']).to be_nil
        expect(message.conversation.additional_attributes['entry_point']).to eq('source' => 'click_to_chat_link')
      end
    end

    context 'when a later message reuses the conversation' do
      it 'preserves the original ad attribution (first touch wins)' do
        first = ad_params(
          { extendedTextMessage: { text: 'Oi, vi o anúncio', contextInfo: { externalAdReply: external_ad_reply } } },
          id: 'ad_msg_first_touch_1'
        )
        follow_up = ad_params({ extendedTextMessage: { text: 'seguindo a conversa' } }, id: 'ad_msg_first_touch_2')

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: first).perform
        conversation = inbox.messages.last.conversation
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: follow_up).perform

        expect(conversation.reload.additional_attributes['referral']).to include('ctwa_clid' => 'ARAaCtwaClid123')
      end

      it 'backfills attribution when the reused conversation had none' do
        plain = ad_params({ extendedTextMessage: { text: 'oi, tudo bem?' } }, id: 'ad_msg_backfill_1')
        ad = ad_params(
          { extendedTextMessage: { text: 'agora vi o anúncio', contextInfo: { externalAdReply: external_ad_reply } } },
          id: 'ad_msg_backfill_2'
        )

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: plain).perform
        conversation = inbox.messages.last.conversation
        expect(conversation.additional_attributes['referral']).to be_nil

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: ad).perform

        expect(conversation.reload.additional_attributes['referral']).to include('ctwa_clid' => 'ARAaCtwaClid123')
      end
    end
  end

  describe 'rich message handling' do
    let(:phone) { '5511912345678' }
    let(:lid) { '12345678' }

    after do
      Redis::Alfred.scan_each(match: "MESSAGE_SOURCE_KEY::#{inbox.id}_*") { |key| Redis::Alfred.delete(key) }
    end

    def rich_params(message, id:)
      raw_message = {
        key: { id: id, remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false, addressingMode: 'pn' },
        pushName: 'Acme Payments',
        messageTimestamp: timestamp,
        message: message
      }
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'notify', messages: [raw_message] } }
    end

    context 'when receiving a hydrated template message' do
      it 'stores the text content and the structured rich payload, not unsupported' do
        params = rich_params(
          { templateMessage: { hydratedTemplate: {
            hydratedContentText: 'Your invoice is ready.', hydratedFooterText: 'Reply STOP to opt out.',
            hydratedButtons: [{ urlButton: { displayText: 'Pay now', url: 'https://acme.io/pay' } }]
          } }, messageContextInfo: { deviceListMetadataVersion: 2 } },
          id: 'rich_tpl_1'
        )

        expect do
          Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
        end.to change(inbox.messages, :count).by(1)

        message = inbox.messages.last
        expect(message.is_unsupported).to be_falsey
        expect(message.content).to eq("Your invoice is ready.\n\nReply STOP to opt out.\n\n▸ Pay now: https://acme.io/pay")
        expect(message.content_attributes['rich']).to include(
          'type' => 'template', 'body' => 'Your invoice is ready.', 'footer' => 'Reply STOP to opt out.',
          'buttons' => [{ 'text' => 'Pay now', 'url' => 'https://acme.io/pay' }]
        )
      end
    end

    context 'when a template carries an externalAdReply (CTWA)' do
      it 'captures the referral with the numeric proto media type mapped' do
        params = rich_params(
          { templateMessage: { hydratedTemplate: { hydratedContentText: 'Promo' },
                               contextInfo: { externalAdReply: { title: 'Ad', mediaType: 2, ctwaClid: 'CLID1' } } } },
          id: 'rich_tpl_ad_1'
        )

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

        message = inbox.messages.last
        expect(message.content_attributes['rich']).to include('type' => 'template', 'body' => 'Promo')
        expect(message.content_attributes['referral']).to include('ctwa_clid' => 'CLID1', 'media_type' => 'video')
      end
    end

    context 'when the rich message quotes another message' do
      it 'anchors the reply to the quoted message' do
        contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: "#{lid}@lid")
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid)
        conversation = create(:conversation, inbox: inbox, contact_inbox: contact_inbox, contact: contact)
        original = create(:message, inbox: inbox, conversation: conversation, source_id: 'QUOTED_RICH_1')

        params = rich_params(
          { templateMessage: { hydratedTemplate: { hydratedContentText: 'Re: your order' },
                               contextInfo: { stanzaId: 'QUOTED_RICH_1' } } },
          id: 'rich_reply_1'
        )

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

        reply = conversation.messages.last
        expect(reply.in_reply_to).to eq(original.id)
        expect(reply.in_reply_to_external_id).to eq('QUOTED_RICH_1')
      end
    end

    context 'when receiving an interactive nativeFlow message' do
      it 'parses the cta_url button from the snake_case params json' do
        params = rich_params(
          { interactiveMessage: { body: { text: 'Pick one' },
                                  nativeFlowMessage: { buttons: [
                                    { name: 'cta_url', buttonParamsJson: '{"display_text":"Buy","url":"https://b.io"}' }
                                  ] } } },
          id: 'rich_interactive_1'
        )

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

        message = inbox.messages.last
        expect(message.is_unsupported).to be_falsey
        expect(message.content).to eq("Pick one\n\n▸ Buy: https://b.io")
        expect(message.content_attributes.dig('rich', 'buttons')).to eq([{ 'text' => 'Buy', 'url' => 'https://b.io' }])
      end
    end

    context 'when the rich message has no renderable content' do
      it 'marks the message as unsupported' do
        params = rich_params({ interactiveMessage: {} }, id: 'rich_empty_1')

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

        message = inbox.messages.last
        expect(message.is_unsupported).to be(true)
        expect(message.content).to be_nil
      end
    end

    context 'when a template has a media header alongside text' do
      it 'attaches the header media and keeps the rich card' do
        params = rich_params(
          { templateMessage: { hydratedTemplate: {
            hydratedContentText: 'Segue a fatura em anexo.',
            documentMessage: { mimetype: 'application/pdf', fileName: 'fatura.pdf' }
          } } },
          id: 'rich_tpl_media_1'
        )
        stub_request(:get, whatsapp_channel.media_url('rich_tpl_media_1')).to_return(status: 200, body: 'fake pdf')

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

        message = inbox.messages.last
        expect(message.is_unsupported).to be_falsey
        expect(message.content_attributes['rich']).to include('body' => 'Segue a fatura em anexo.')
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('file')
        expect(message.attachments.first.file.filename.to_s).to eq('fatura.pdf')
      end
    end

    context 'when a template is only a media header (no text/buttons)' do
      it 'attaches the media and does not mark the message unsupported' do
        params = rich_params(
          { templateMessage: { hydratedTemplate: { imageMessage: { mimetype: 'image/jpeg' } } } },
          id: 'rich_tpl_media_only_1'
        )
        stub_request(:get, whatsapp_channel.media_url('rich_tpl_media_only_1')).to_return(status: 200, body: 'fake image')

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

        message = inbox.messages.last
        expect(message.is_unsupported).to be_falsey
        expect(message.content).to be_nil
        expect(message.content_attributes['rich']).to be_nil
        expect(message.attachments.count).to eq(1)
        expect(message.attachments.first.file_type).to eq('image')
      end
    end

    context 'when receiving a poll' do
      it 'renders the question and options as a rich card' do
        params = rich_params(
          { pollCreationMessage: { name: 'Qual horário?', options: [{ optionName: 'Manhã' }, { optionName: 'Tarde' }] } },
          id: 'rich_poll_1'
        )

        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

        message = inbox.messages.last
        expect(message.is_unsupported).to be_falsey
        expect(message.content).to eq("Qual horário?\n\n▸ Manhã\n\n▸ Tarde")
        expect(message.content_attributes['rich']).to include('type' => 'poll', 'title' => 'Qual horário?')
      end
    end
  end

  describe 'masked message handling' do
    let(:phone) { '18668392077' }

    after do
      Redis::Alfred.scan_each(match: "MESSAGE_SOURCE_KEY::#{inbox.id}_*") { |key| Redis::Alfred.delete(key) }
    end

    # WhatsApp withholds an authentication template (a verification code) from linked
    # devices and sends a placeholder in its place, so the connector never sees content.
    it 'flags the message as masked so the bubble can name the reason' do
      raw_message = {
        key: { id: 'masked_1', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false },
        messageTimestamp: timestamp,
        message: { messageContextInfo: { deviceListMetadataVersion: 2 }, placeholderMessage: { type: 0 } },
        verifiedBizName: 'OpenAI'
      }
      params = { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert',
                 data: { type: 'notify', messages: [raw_message] } }

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
      end.to change(Message, :count).by(1)

      message = inbox.messages.last
      expect(message.content).to be_nil
      expect(message.is_unsupported).to be(true)
      expect(message.is_masked).to be(true)
    end

    it 'leaves an unsupported message unflagged, so the two read apart' do
      raw_message = {
        key: { id: 'masked_2', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false },
        messageTimestamp: timestamp,
        message: { someUnknownMessage: {} }
      }
      params = { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert',
                 data: { type: 'notify', messages: [raw_message] } }

      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

      message = inbox.messages.last
      expect(message.is_unsupported).to be(true)
      expect(message.is_masked).to be_nil
    end
  end

  describe 'view-once message handling' do
    let(:phone) { '18668392077' }

    after do
      Redis::Alfred.scan_each(match: "MESSAGE_SOURCE_KEY::#{inbox.id}_*") { |key| Redis::Alfred.delete(key) }
    end

    def deliver(*entries)
      params = { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert',
                 data: { type: 'notify', messages: entries } }
      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
    end

    # WhatsApp does not deliver view-once content to linked devices, so Baileys forwards the
    # key alone. Raising on it dead-lettered the job and the agent never learned it arrived.
    it 'stores a content-less row flagged as view-once' do
      entry = { key: { id: 'view_once_1', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false, isViewOnce: true },
                messageTimestamp: timestamp, pushName: 'Ana' }

      expect { deliver(entry) }.to change(inbox.messages, :count).by(1)

      message = inbox.messages.find_by(source_id: 'view_once_1')
      expect(message.content).to be_nil
      expect(message).to be_incoming
      expect(message.is_unsupported).to be(true)
      expect(message.is_view_once).to be(true)
    end

    it 'stores one sent from the paired phone as outgoing' do
      entry = { key: { id: 'view_once_2', remoteJid: "#{phone}@s.whatsapp.net", fromMe: true, isViewOnce: true },
                messageTimestamp: timestamp, status: 2 }

      deliver(entry)

      message = inbox.messages.find_by(source_id: 'view_once_2')
      expect(message).to be_outgoing
      expect(message.is_view_once).to be(true)
    end

    # The batch is iterated, so an entry that raised also lost every entry after it.
    it 'keeps processing the entries after it in the same payload' do
      view_once = { key: { id: 'view_once_3', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false, isViewOnce: true },
                    messageTimestamp: timestamp }
      text = { key: { id: 'after_view_once', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false },
               messageTimestamp: timestamp, message: { conversation: 'oi' } }

      deliver(view_once, text)

      expect(inbox.messages.find_by(source_id: 'after_view_once')&.content).to eq('oi')
    end

    it 'ignores an entry with no message that is not view-once, whether the key is absent or null' do
      absent = { key: { id: 'no_message_1', remoteJid: "#{phone}@s.whatsapp.net", fromMe: false }, messageTimestamp: timestamp }
      null = absent.merge(key: absent[:key].merge(id: 'no_message_2'), message: nil)

      expect { deliver(absent, null) }.not_to change(Message, :count)
    end
  end

  describe 'location message handling' do
    let(:phone) { '5511912345678' }
    let(:lid) { '12345678' }

    after do
      Redis::Alfred.scan_each(match: "MESSAGE_SOURCE_KEY::#{inbox.id}_*") { |key| Redis::Alfred.delete(key) }
    end

    def loc_params(message, id:)
      raw = { key: { id: id, remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false, addressingMode: 'pn' },
              pushName: 'Lead', messageTimestamp: timestamp, message: message }
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'notify', messages: [raw] } }
    end

    it 'persists a native location attachment (real shape: coordinates only)' do
      params = loc_params({ locationMessage: { degreesLatitude: -18.9202171, degreesLongitude: -48.2694733 } }, id: 'loc_1')

      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

      message = inbox.messages.last
      expect(message.is_unsupported).to be_falsey
      attachment = message.attachments.first
      expect(attachment.file_type).to eq('location')
      expect(attachment.coordinates_lat).to eq(-18.9202171)
      expect(attachment.coordinates_long).to eq(-48.2694733)
    end

    it 'uses name/address as the fallback title and keeps the place url' do
      params = loc_params(
        { locationMessage: { degreesLatitude: -23.5, degreesLongitude: -46.6, name: 'Padaria', address: 'Rua X, 1',
                             url: 'https://maps.example/p' } },
        id: 'loc_2'
      )

      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

      attachment = inbox.messages.last.attachments.first
      expect(attachment.fallback_title).to eq('Padaria, Rua X, 1')
      expect(attachment.external_url).to eq('https://maps.example/p')
    end

    it 'anchors the reply when the location quotes another message' do
      contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: "#{lid}@lid")
      contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid)
      conversation = create(:conversation, inbox: inbox, contact_inbox: contact_inbox, contact: contact)
      original = create(:message, inbox: inbox, conversation: conversation, source_id: 'QUOTED_LOC_1')

      params = loc_params(
        { locationMessage: { degreesLatitude: -23.5, degreesLongitude: -46.6, contextInfo: { stanzaId: 'QUOTED_LOC_1' } } },
        id: 'loc_reply_1'
      )

      Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform

      reply = conversation.messages.last
      expect(reply.in_reply_to).to eq(original.id)
      expect(reply.in_reply_to_external_id).to eq('QUOTED_LOC_1')
    end
  end

  describe 'contact message handling' do
    let(:phone) { '5511912345678' }
    let(:lid) { '12345678' }
    let(:vcard) { "BEGIN:VCARD\nVERSION:3.0\nFN:Algar\nTEL;type=Mobile;waid=553498840123:+55 34 9884-0123\nEND:VCARD" }

    after do
      Redis::Alfred.scan_each(match: "MESSAGE_SOURCE_KEY::#{inbox.id}_*") { |key| Redis::Alfred.delete(key) }
    end

    def contact_params(message, id:)
      raw = { key: { id: id, remoteJid: "#{phone}@s.whatsapp.net", remoteJidAlt: "#{lid}@lid", fromMe: false, addressingMode: 'pn' },
              pushName: 'Lead', messageTimestamp: timestamp, message: message }
      { webhookVerifyToken: webhook_verify_token, event: 'messages.upsert', data: { type: 'notify', messages: [raw] } }
    end

    it 'persists a single contact as a native contact attachment' do
      params = contact_params({ contactMessage: { displayName: 'Algar', vcard: vcard } }, id: 'contact_1')

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
      end.to change(inbox.messages, :count).by(1)

      message = inbox.messages.last
      expect(message.is_unsupported).to be_falsey
      expect(message.content).to eq('Algar - +55 34 9884-0123')
      attachment = message.attachments.first
      expect(attachment.file_type).to eq('contact')
      expect(attachment.fallback_title).to eq('+55 34 9884-0123')
      expect(attachment.meta).to eq('firstName' => 'Algar')
    end

    it 'creates one message per contact for a contactsArrayMessage (real shape)' do
      other = "BEGIN:VCARD\nVERSION:3.0\nFN:+551140037752\nTEL;type=Mobile;waid=551140037752:+55 11 4003-7752\nEND:VCARD"
      params = contact_params(
        { contactsArrayMessage: { displayName: '2 contacts', contacts: [
          { displayName: '+551140037752', vcard: other }, { displayName: 'Algar', vcard: vcard }
        ] } },
        id: 'contacts_array_1'
      )

      expect do
        Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
      end.to change(inbox.messages, :count).by(2)

      messages = inbox.messages.last(2)
      expect(messages.map { |m| m.attachments.first&.file_type }).to eq(%w[contact contact])
      expect(messages.map(&:content)).to contain_exactly('+55 11 4003-7752', 'Algar - +55 34 9884-0123')
    end
  end
end
