require 'rails_helper'

describe Whatsapp::IncomingMessageBaileysService do
  describe '#perform' do
    let(:webhook_verify_token) { 'valid_token' }
    let!(:whatsapp_channel) do
      create(:channel_whatsapp,
             provider: 'baileys',
             provider_config: { webhook_verify_token: webhook_verify_token },
             validate_provider_config: false,
             received_messages: false)
    end
    let(:inbox) { whatsapp_channel.inbox }

    context 'when webhook verify token is invalid' do
      it 'raises an InvalidWebhookVerifyToken error' do
        params = { webhookVerifyToken: 'invalid_token' }

        expect do
          described_class.new(inbox: inbox, params: params).perform
        end.to(raise_error { |error| expect(error.class.name).to eq('Whatsapp::IncomingMessageBaileysService::InvalidWebhookVerifyToken') })
      end
    end

    context 'when event is blank' do
      it 'returns early and does nothing' do
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: '',
          data: { connection: 'open' }
        }
        service = described_class.new(inbox: inbox, params: params)
        allow(service).to receive(:respond_to?)

        service.perform

        expect(service).not_to have_received(:respond_to?)
      end
    end

    context 'when data is blank' do
      it 'returns early and does nothing' do
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'connection.update',
          data: {}
        }
        service = described_class.new(inbox: inbox, params: params)
        allow(service).to receive(:respond_to?)

        service.perform

        expect(service).not_to have_received(:respond_to?)
      end
    end

    context 'when event is unsupported' do
      it 'logs a warning message' do
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'unsupported.event',
          data: 'some-data'
        }
        allow(Rails.logger).to receive(:warn).with('Baileys unsupported event: unsupported.event')

        described_class.new(inbox: inbox, params: params).perform

        expect(Rails.logger).to have_received(:warn)
      end
    end

    it 'dispatches the provider.event_received event' do
      params = {
        webhookVerifyToken: webhook_verify_token,
        event: 'some.event',
        data: 'some-data'
      }
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      described_class.new(inbox: inbox, params: params).perform

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        Events::Types::PROVIDER_EVENT_RECEIVED,
        kind_of(Time),
        inbox: inbox,
        event: params[:event],
        payload: params[:data]
      )
    end

    context 'when processing message-capping.update event' do
      it 'persists the UI-relevant cap keys and drops server_sent_timestamp' do
        params = {
          webhookVerifyToken: webhook_verify_token,
          event: 'message-capping.update',
          data: {
            capping_status: 'FIRST_WARNING',
            ote_status: 'ELIGIBLE',
            mv_status: 'NOT_ELIGIBLE',
            total_quota: 100,
            used_quota: 80,
            cycle_end_timestamp: '1781699999',
            server_sent_timestamp: '1781645846'
          }
        }

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.reload.provider_connection['new_chat_cap']).to eq(
          'capping_status' => 'FIRST_WARNING',
          'ote_status' => 'ELIGIBLE',
          'mv_status' => 'NOT_ELIGIBLE',
          'total_quota' => 100,
          'used_quota' => 80,
          'cycle_end_timestamp' => '1781699999'
        )
      end
    end

    context 'when processing connection.update event' do
      let(:base_params) { { webhookVerifyToken: webhook_verify_token, event: 'connection.update' } }

      it 'updates the channel provider_connection' do
        params = base_params.merge(
          {
            data: {
              connection: 'open',
              qrDataUrl: 'data:image/jpeg;base64,',
              error: 'wrong_phone_number'
            }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection).to include(
          'connection' => 'open',
          'qr_data_url' => 'data:image/jpeg;base64,',
          'error' => I18n.t('errors.inboxes.channel.provider_connection.wrong_phone_number')
        )
      end

      it "logs an error message if there's an error" do
        params = base_params.merge(
          {
            data: { error: 'wrong_phone_number' }
          }
        )
        allow(Rails.logger).to receive(:error).with('Baileys connection error: wrong_phone_number')

        described_class.new(inbox: inbox, params: params).perform

        expect(Rails.logger).to have_received(:error)
      end

      it "keeps connection value if it's not present in the data" do
        inbox.channel.update_provider_connection!(connection: 'connecting')
        params = base_params.merge(
          {
            data: { qrDataUrl: 'data:image/jpeg;base64,' }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection['connection']).to eq('connecting')
      end

      it "removes qr_data_url value if it's not present in the data" do
        inbox.channel.update_provider_connection!(qr_data_url: 'data:image/jpeg;base64,')
        params = base_params.merge(
          {
            data: { connection: 'open' }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection['qr_data_url']).to be_nil
      end

      it "removes error value if it's not present in the data" do
        inbox.channel.update_provider_connection!(error: 'wrong_phone_number')
        params = base_params.merge(
          {
            data: { connection: 'open' }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection['error']).to be_nil
      end

      it 'persists the quarantine reported with a reconnect loop and clears it on the next update' do
        params = base_params.merge(
          {
            data: {
              error: 'reconnect_loop_detected',
              quarantine: { strikes: 3, until: '2026-07-31T12:00:00.000Z' }
            }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection).to include(
          'error' => I18n.t('errors.inboxes.channel.provider_connection.reconnect_loop_detected'),
          'quarantine' => { 'strikes' => 3, 'until' => '2026-07-31T12:00:00.000Z' }
        )

        next_cycle = base_params.merge({ data: { connection: 'connecting' } })
        described_class.new(inbox: inbox, params: next_cycle).perform

        expect(inbox.channel.reload.provider_connection['quarantine']).to be_nil
      end

      # The connection keeps receiving and passing health checks while every send times
      # out, so this webhook is the only thing that says so. `action` is what tells an
      # operator whether the provider already recreated the socket or is holding off —
      # and holding off is when a human has to step in.
      it 'persists a reported send stall and clears it only when the connection reopens' do
        params = base_params.merge(
          {
            data: {
              error: 'send_stall_detected',
              sendStall: {
                consecutiveTimeouts: 3,
                stalledForMs: 120_000,
                action: 'suppressed',
                until: '2026-08-21T12:00:00.000Z'
              }
            }
          }
        )

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.channel.provider_connection).to include(
          'error' => I18n.t('errors.inboxes.channel.provider_connection.send_stall_detected'),
          'send_stall' => {
            'consecutive_timeouts' => 3,
            'stalled_for_ms' => 120_000,
            'action' => 'suppressed',
            'until' => '2026-08-21T12:00:00.000Z'
          }
        )

        # The provider reports a stall once per episode. An unrelated update in the
        # meantime — a standalone reachoutTimeLock push carries no sendStall — must not
        # clear the warning, because nothing would ever say it again while the connection
        # is still mute.
        unrelated = base_params.merge(
          { data: { reachoutTimeLock: { isActive: false } } }
        )
        described_class.new(inbox: inbox, params: unrelated).perform

        expect(inbox.channel.reload.provider_connection['send_stall']).to include(
          'consecutive_timeouts' => 3
        )
        # The error string is the only half of this warning an operator can see:
        # provider_connection_admin_data serializes error and qr_data_url, and send_stall
        # reaches no serializer. Preserving the detail without the string preserves nothing
        # anyone reads.
        expect(inbox.channel.provider_connection['error']).to eq(
          I18n.t('errors.inboxes.channel.provider_connection.send_stall_detected')
        )

        # `open` is a NEW socket, hence a new keystore mutex, whether the provider
        # restarted it or WhatsApp dropped it. That is the one event that means recovery.
        next_update = base_params.merge({ data: { connection: 'open' } })
        described_class.new(inbox: inbox, params: next_update).perform

        expect(inbox.channel.reload.provider_connection['send_stall']).to be_nil
        expect(inbox.channel.provider_connection['error']).to be_nil
      end

      context 'with reach-out time-lock (error 463 / account restriction)' do
        let(:reachout_data) do
          { isActive: true, timeEnforcementEnds: '2026-06-19T21:52:39.000Z', enforcementType: 'RESTRICT_ALL_COMPANIONS' }
        end

        it 'persists the lock from a standalone reachoutTimeLock push and keeps the connection' do
          inbox.channel.update_provider_connection!(connection: 'open')
          params = base_params.merge(data: { reachoutTimeLock: reachout_data })

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['connection']).to eq('open')
          expect(inbox.channel.provider_connection['reachout_time_lock']).to eq(
            'is_active' => true,
            'time_enforcement_ends' => '2026-06-19T21:52:39.000Z',
            'enforcement_type' => 'RESTRICT_ALL_COMPANIONS'
          )
        end

        it 'preserves an existing lock when a connection-only update arrives' do
          inbox.channel.update_provider_connection!(
            connection: 'open',
            reachout_time_lock: { is_active: true, time_enforcement_ends: '2026-06-19T21:52:39.000Z', enforcement_type: 'RESTRICT_ALL_COMPANIONS' }
          )
          params = base_params.merge(data: { connection: 'connecting' })

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['connection']).to eq('connecting')
          expect(inbox.channel.provider_connection['reachout_time_lock']).to include('is_active' => true)
        end

        it 'records the cleared state when isActive is false' do
          params = base_params.merge(data: { reachoutTimeLock: { isActive: false, enforcementType: 'DEFAULT' } })

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['reachout_time_lock']).to eq('is_active' => false, 'enforcement_type' => 'DEFAULT')
        end

        it 'persists only is_active when the deadline and type are absent' do
          params = base_params.merge(data: { reachoutTimeLock: { isActive: true } })

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['reachout_time_lock']).to eq('is_active' => true)
        end

        it 'discards a stale-epoch reachoutTimeLock push' do
          inbox.channel.update_provider_connection!(connection: 'open', epoch: 7)
          params = base_params.merge(data: { reachoutTimeLock: reachout_data, epoch: 6 })

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['reachout_time_lock']).to be_nil
        end
      end

      context 'with new-chat cap (quota)' do
        it 'preserves an existing cap when a connection-only update arrives' do
          inbox.channel.update_provider_connection!(
            connection: 'open',
            new_chat_cap: { capping_status: 'CAPPED', total_quota: 100, used_quota: 100 }
          )
          params = base_params.merge(data: { connection: 'connecting' })

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['connection']).to eq('connecting')
          expect(inbox.channel.provider_connection['new_chat_cap']).to include('capping_status' => 'CAPPED')
        end
      end

      context 'with lease epochs (multi-instance baileys-api)' do
        it 'persists the epoch alongside the connection state' do
          params = base_params.merge(
            {
              data: { connection: 'open', epoch: 7 }
            }
          )

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection).to include('connection' => 'open', 'epoch' => 7)
        end

        it 'discards events carrying an epoch older than the last seen' do
          # A late retry from a previous owner (e.g. "reconnecting") must not
          # overwrite the current owner's "open".
          inbox.channel.update_provider_connection!(connection: 'open', epoch: 7)
          params = base_params.merge(
            {
              data: { connection: 'reconnecting', epoch: 6 }
            }
          )

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['connection']).to eq('open')
          expect(inbox.channel.provider_connection['epoch']).to eq(7)
        end

        it 'accepts events with the same epoch as the last seen' do
          inbox.channel.update_provider_connection!(connection: 'reconnecting', epoch: 7)
          params = base_params.merge(
            {
              data: { connection: 'open', epoch: 7 }
            }
          )

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['connection']).to eq('open')
        end

        it 'accepts events without an epoch (older baileys-api versions)' do
          inbox.channel.update_provider_connection!(connection: 'reconnecting', epoch: 7)
          params = base_params.merge(
            {
              data: { connection: 'open' }
            }
          )

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection['connection']).to eq('open')
        end

        it 'accepts any epoch when none has been seen yet' do
          inbox.channel.update_provider_connection!(connection: 'reconnecting')
          params = base_params.merge(
            {
              data: { connection: 'open', epoch: 3 }
            }
          )

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel.provider_connection).to include('connection' => 'open', 'epoch' => 3)
        end

        it 'acquires a row lock so the epoch check and update are atomic' do
          params = base_params.merge({ data: { connection: 'open', epoch: 7 } })
          expect(inbox.channel).to receive(:with_lock).and_call_original

          described_class.new(inbox: inbox, params: params).perform
        end
      end
    end

    context 'when processing messages.upsert event' do
      # NOTE: We always try fetching profile picture for new contacts on messages.upsert, so we must stub this request.
      before { stub_profile_pic_fetch }

      let(:timestamp) { Time.current.to_i }
      let(:raw_message) do
        {
          key: { id: 'msg_123', remoteJid: '12345678@lid', remoteJidAlt: '5511998765432@s.whatsapp.net', fromMe: false, addressingMode: 'lid' },
          pushName: 'John Doe',
          messageTimestamp: timestamp,
          message: { conversation: 'Hello from Baileys' }
        }
      end
      let(:params) do
        {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.upsert',
          data: {
            type: 'notify',
            messages: [raw_message]
          }
        }
      end

      it 'creates message with external_created_at' do
        described_class.new(inbox: inbox, params: params).perform

        conversation = inbox.conversations.last
        message = conversation.messages.last

        expect(message).to be_present
        expect(message.content_attributes[:external_created_at]).to eq(timestamp)
      end

      # A contact created by hand or through the API has no contact_inbox, so nothing but
      # its number can find it, and the builder matched that exactly: WhatsApp reporting
      # the other ninth-digit form filed a second, unblocked contact that the bot answered
      # (#776).
      context 'when a contact with no contact_inbox holds the other ninth-digit form' do
        [
          ['5511998765432', '+551198765432', 'the message has the ninth digit'],
          ['551198765432', '+5511998765432', 'the message has no ninth digit']
        ].each do |reported, stored, label|
          it "files the message under that contact when #{label}" do
            existing = create(:contact, account: inbox.account, name: 'John Doe', phone_number: stored, blocked: true)
            raw_message[:key][:remoteJidAlt] = "#{reported}@s.whatsapp.net"

            expect { described_class.new(inbox: inbox, params: params).perform }
              .not_to change(inbox.account.contacts, :count)

            expect(inbox.contact_inboxes.sole.contact_id).to eq(existing.id)
            expect(existing.reload.blocked).to be(true)
            # Found, the block holds: nothing reaches the bot (#793).
            expect(inbox.conversations).to be_empty
          end
        end

        it 'does not take an Argentine landline for the mobile that reported' do
          landline = create(:contact, account: inbox.account, name: 'Fixo', phone_number: '+541123456789')
          raw_message[:key][:remoteJidAlt] = '5491123456789@s.whatsapp.net'

          expect { described_class.new(inbox: inbox, params: params).perform }
            .to change(inbox.account.contacts, :count).by(1)
          expect(landline.reload.phone_number).to eq('+541123456789')
        end

        it 'does not reach a contact of another account' do
          create(:contact, phone_number: '+551198765432')

          expect { described_class.new(inbox: inbox, params: params).perform }
            .to change(inbox.account.contacts, :count).by(1)
        end
      end

      context 'when updating contact avatar' do
        it 'enqueues the contact avatar update job for new contacts' do
          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          contact = conversation.contact

          expect(Channels::Whatsapp::BaileysUpdateContactAvatarJob).to have_been_enqueued.with(contact, inbox, '5511998765432')
        end

        it 'does not enqueue the contact avatar update job when contact already has avatar attached' do
          contact = create(:contact, account: inbox.account, name: 'John Doe', phone_number: '+5511998765432')
          contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')

          described_class.new(inbox: inbox, params: params).perform

          expect(Channels::Whatsapp::BaileysUpdateContactAvatarJob).not_to have_been_enqueued
        end
      end

      context 'when message type is unsupported' do
        it 'creates message with is_unsupported' do
          raw_message[:message] = { unsupported: 'message' }

          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last

          expect(message).to be_present
          expect(message.content_attributes[:is_unsupported]).to be(true)
        end
      end

      context 'when message is protocol message' do
        it 'does not create contact inbox nor message' do
          raw_message[:message] = { protocolMessage: { type: 1 } }

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.messages).to be_empty
          expect(inbox.contact_inboxes).to be_empty
        end

        it 'does not call channel received_messages method' do
          raw_message[:message] = { protocolMessage: { type: 1 } }

          allow(inbox.channel).to receive(:received_messages)

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel).not_to have_received(:received_messages)
        end
      end

      context 'when message is context message' do
        it 'does not create contact inbox nor message' do
          raw_message[:message] = { 'messageContextInfo': { 'deviceListMetadata': {},
                                                            'deviceListMetadataVersion': 2,
                                                            'messageSecret': '********' } }
          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.messages).to be_empty
          expect(inbox.contact_inboxes).to be_empty
        end
      end

      context 'when message is edited message' do
        it 'does not create contact inbox nor message' do
          raw_message[:message] = { editedMessage: { message: { protocolMessage: { editedMessage: { documentMessage: 1 } } } } }

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.messages).to be_empty
          expect(inbox.contact_inboxes).to be_empty
        end
      end

      context 'when message is a revoke (contact deleted for everyone)' do
        let(:original_message) do
          contact = create(:contact, account: inbox.account, phone_number: '+5511998765432')
          contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox, source_id: '5511998765432')
          conversation = create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox)
          create(:message, conversation: conversation, source_id: 'original_msg_id', content: 'secret message')
        end

        it 'flags the original message as deleted by the contact and keeps the content' do
          original_message
          raw_message[:message] = { protocolMessage: { key: { id: 'original_msg_id' }, type: 'REVOKE' } }

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.not_to(change { inbox.messages.count })

          original_message.reload
          expect(original_message.content).to eq('secret message')
          expect(original_message.content_attributes['deleted_by_contact']).to be(true)
        end

        it 'does nothing when the revoked message is unknown' do
          raw_message[:message] = { protocolMessage: { key: { id: 'unknown_id' }, type: 'REVOKE' } }

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.messages).to be_empty
          expect(inbox.contact_inboxes).to be_empty
        end
      end

      context 'when message is not from a user' do
        it 'does not create a conversation' do
          raw_message[:key][:remoteJid] = 'status@broadcast'

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.conversations).to be_empty
        end
      end

      context 'when message is saved' do
        it 'calls channel received_messages method' do
          allow(inbox.channel).to receive(:received_messages)

          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last

          expect(inbox.channel).to have_received(:received_messages).with([message], conversation)
        end

        it 'does not call channel received_messages method if message is outgoing' do
          raw_message[:key][:fromMe] = true
          create(:account_user, account: inbox.account)

          allow(inbox.channel).to receive(:received_messages)

          described_class.new(inbox: inbox, params: params).perform

          expect(inbox.channel).not_to have_received(:received_messages)
        end
      end

      context 'when message type is text' do
        context 'when has key conversation' do # rubocop:disable RSpec/NestedGroups
          it 'creates an incoming message' do
            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last

            expect(message).to be_present
            expect(message.content).to eq('Hello from Baileys')
            expect(message.sender).to be_present
            expect(message.sender.name).to eq('John Doe')
            expect(message.message_type).to eq('incoming')
          end

          it 'creates an outgoing message' do
            raw_message[:key][:fromMe] = true
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last

            expect(message).to be_present
            expect(message.content).to eq('Hello from Baileys')
            expect(conversation.contact.name).to eq('5511998765432')
            expect(message.message_type).to eq('outgoing')
          end

          it 'updates the contact name when name is the phone number and message has a pushName' do
            create(:contact, account: inbox.account, name: '5511998765432')

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('John Doe')
          end

          it 'updates the contact name when name is the phone number and message has a verifiedBizName' do
            raw_message[:verifiedBizName] = 'Verified John'
            create(:contact, account: inbox.account, name: '5511998765432')

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('Verified John')
          end

          it 'creates contact with LID only when phone number is not present' do
            raw_message[:key][:remoteJid] = '87654321@lid'
            raw_message[:key][:remoteJidAlt] = nil

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            contact = conversation.contact
            contact_inbox = conversation.contact_inbox

            expect(contact).to be_present
            expect(contact.phone_number).to be_nil
            expect(contact.identifier).to eq('87654321@lid')
            expect(contact.name).to eq('John Doe')
            expect(contact_inbox.source_id).to eq('87654321')
          end

          it 'creates contact with phone number as name on outgoing message' do
            raw_message[:key][:fromMe] = true
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('5511998765432')
          end

          it 'creates contact with phone number as name on incoming message if pushName is not present' do
            raw_message[:pushName] = nil
            create(:account_user, account: inbox.account)

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            expect(conversation.contact.name).to eq('5511998765432')
          end

          it 'migrates existing phone-based contact inbox to LID-based when receiving message with LID' do
            contact = create(:contact, account: inbox.account, name: 'Existing Contact', phone_number: '+5511998765432')
            contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5511998765432')

            described_class.new(inbox: inbox, params: params).perform

            contact_inbox.reload
            contact.reload

            expect(contact_inbox.source_id).to eq('12345678')
            expect(contact.identifier).to eq('12345678@lid')
            expect(contact.phone_number).to eq('+5511998765432')
          end

          it 'creates a message on an existing conversation' do
            contact = create(:contact, account: inbox.account, name: 'John Doe')
            contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')
            existing_conversation = create(:conversation, inbox: inbox, contact_inbox: contact_inbox, contact: contact)

            described_class.new(inbox: inbox, params: params).perform

            message = existing_conversation.messages.last
            expect(message.sender).to eq(contact)
          end

          it 'does not create a message if it already exists' do
            message = create(:message, inbox: inbox, source_id: 'msg_123')

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            messages = conversation.messages
            expect(messages).to eq([message])
          end

          it 'does not create duplicate message when source_id is set after contact lock is acquired' do
            # This tests the race condition fix:
            # 1. Agent sends message from Chatwoot (message created without source_id)
            # 2. Webhook arrives before source_id is saved
            # 3. Webhook handler times out on channel lock and proceeds
            # 4. Inside contact lock, we re-check for message by source_id
            # 5. By then, source_id should be set, so duplicate is prevented

            # Create contact and conversation that will be found
            contact = create(:contact, account: inbox.account, identifier: '12345678@lid', phone_number: '+5511998765432')
            contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')
            conversation = create(:conversation, inbox: inbox, contact_inbox: contact_inbox, contact: contact)

            # Simulate the race: message exists but will only be found on the re-check inside contact lock
            existing_message = create(:message, inbox: inbox, conversation: conversation)

            # First call returns nil (simulating message not having source_id yet)
            # Second call (inside contact lock) returns the message
            service = described_class.new(inbox: inbox, params: params)
            call_count = 0
            allow(service).to receive(:find_message_by_source_id).and_wrap_original do |_method, _source_id|
              call_count += 1
              call_count == 1 ? nil : existing_message
            end

            service.perform

            # Should not create a new conversation or message
            expect(inbox.conversations.count).to eq(1)
            expect(inbox.messages.count).to eq(1)
          end

          it 'does not create a message if it is already being processed' do
            # Simulate lock already acquired by returning false from SETNX
            allow(Redis::Alfred).to receive(:set)
              .with(format_message_source_key('msg_123'), true, nx: true, ex: 1.day)
              .and_return(false)

            described_class.new(inbox: inbox, params: params).perform

            expect(inbox.conversations).to be_empty
          end

          it 'caches and clears message source id in Redis' do
            # Allow all Redis::Alfred calls (contact lock uses different keys)
            allow(Redis::Alfred).to receive(:set).and_call_original
            allow(Redis::Alfred).to receive(:delete).and_call_original

            # Stub message lock specifically
            allow(Redis::Alfred).to receive(:set)
              .with(format_message_source_key('msg_123'), true, nx: true, ex: 1.day)
              .and_return(true)
            allow(Redis::Alfred).to receive(:delete).with(format_message_source_key('msg_123'))

            described_class.new(inbox: inbox, params: params).perform

            expect(Redis::Alfred).to have_received(:set).with(format_message_source_key('msg_123'), true, nx: true, ex: 1.day)
            expect(Redis::Alfred).to have_received(:delete).with(format_message_source_key('msg_123'))
          end

          it 'clears lock even when an exception occurs after acquiring it' do
            # Bug: no ensure block meant exceptions left lock stuck forever
            # Fix: use ensure block to always clear lock when acquired
            # Allow all Redis::Alfred calls (contact lock uses different keys)
            allow(Redis::Alfred).to receive(:set).and_call_original
            allow(Redis::Alfred).to receive(:delete).and_call_original

            # Stub message lock specifically
            allow(Redis::Alfred).to receive(:set)
              .with(format_message_source_key('msg_123'), true, nx: true, ex: 1.day)
              .and_return(true)
            allow(Redis::Alfred).to receive(:delete).with(format_message_source_key('msg_123'))

            service = described_class.new(inbox: inbox, params: params)
            allow(service).to receive(:handle_create_message).and_raise(StandardError, 'simulated error')

            expect { service.perform }.to raise_error(StandardError, 'simulated error')

            expect(Redis::Alfred).to have_received(:delete).with(format_message_source_key('msg_123'))
          end
        end

        context 'when is a extendedTextMessage that has key text' do # rubocop:disable RSpec/NestedGroups
          it 'creates an incoming message' do
            raw_message[:message] = { extendedTextMessage: { text: 'Hello from Baileys' } }

            described_class.new(inbox: inbox, params: params).perform

            conversation = inbox.conversations.last
            message = conversation.messages.last
            expect(message).to be_present
            expect(message.content).to eq('Hello from Baileys')
            expect(message.message_type).to eq('incoming')
            expect(message.sender).to be_present
            expect(message.sender.name).to eq('John Doe')
          end
        end
      end

      context 'when message type is reaction' do
        let!(:message) do
          contact = create(:contact, account: inbox.account, name: '5511998765432')
          contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')
          conversation = create(:conversation, inbox: inbox, contact_inbox: contact_inbox)
          create(:message, inbox: inbox, conversation: conversation, source_id: 'msg_123')
        end

        it 'creates the reaction' do
          raw_message[:key][:id] = 'reaction_123'
          raw_message[:message] = {
            reactionMessage: {
              key: { remoteJid: '12345678@lid', fromMe: true, id: 'msg_123' },
              text: '👍'
            }
          }

          described_class.new(inbox: inbox, params: params).perform

          reaction = message.conversation.messages.last
          expect(reaction.is_reaction).to be(true)
          expect(reaction.in_reply_to).to eq(message.id)
          expect(reaction.in_reply_to_external_id).to eq(message.source_id)
        end

        it 'anchors the reaction to the target message conversation when it is resolved instead of opening a new one' do
          message.conversation.update!(status: :resolved)
          raw_message[:key][:id] = 'reaction_123'
          raw_message[:message] = {
            reactionMessage: {
              key: { remoteJid: '12345678@lid', fromMe: true, id: 'msg_123' },
              text: '👍'
            }
          }

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.not_to change(Conversation, :count)

          reaction = message.conversation.reload.messages.last
          expect(reaction.is_reaction).to be(true)
          expect(reaction.conversation_id).to eq(message.conversation.id)
          expect(reaction.in_reply_to_external_id).to eq(message.source_id)
        end

        it 'does not create the reaction if content is empty' do
          raw_message[:key][:id] = 'reaction_123'
          raw_message[:message] = {
            reactionMessage: {
              key: { remoteJid: '12345678@lid', fromMe: true, id: 'msg_123' },
              text: ''
            }
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.conversation.messages.count).to eq(1)
        end

        it 'marks an existing incoming reaction as removed when webhook arrives with empty text' do
          existing_reaction = create(:message,
                                     conversation: message.conversation,
                                     sender: message.conversation.contact_inbox.contact,
                                     message_type: :incoming,
                                     content: '👍',
                                     content_attributes: { is_reaction: true, in_reply_to_external_id: message.source_id })
          raw_message[:key][:id] = 'reaction_removal_456'
          raw_message[:message] = {
            reactionMessage: {
              key: { remoteJid: '12345678@lid', fromMe: true, id: 'msg_123' },
              text: ''
            }
          }

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.not_to(change { message.conversation.messages.count })

          existing_reaction.reload
          expect(existing_reaction.content).to eq('')
          expect(existing_reaction.content_attributes['deleted']).to be true
        end

        it 'dispatches conversation.updated after marking a reaction as removed' do
          create(:message,
                 conversation: message.conversation,
                 sender: message.conversation.contact_inbox.contact,
                 message_type: :incoming,
                 content: '👍',
                 content_attributes: { is_reaction: true, in_reply_to_external_id: message.source_id })
          dispatched = []
          allow_any_instance_of(Conversation).to receive(:dispatch_conversation_updated_event) do |conv| # rubocop:disable RSpec/AnyInstance
            dispatched << conv.id
          end
          raw_message[:key][:id] = 'reaction_removal_789'
          raw_message[:message] = {
            reactionMessage: {
              key: { remoteJid: '12345678@lid', fromMe: true, id: 'msg_123' },
              text: ''
            }
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(dispatched).to include(message.conversation.id)
        end

        it 'skips reaction removal for outgoing echoes so the local controller update is not clobbered' do
          # Mirror the post-controller state: the Chatwoot reactions controller
          # already toggled the senderless outgoing row to deleted, so the
          # echoed fromMe webhook should hit the active-only filter and no-op.
          existing_reaction = create(:message,
                                     conversation: message.conversation,
                                     sender: nil,
                                     message_type: :outgoing,
                                     content: '',
                                     content_attributes: { is_reaction: true, in_reply_to_external_id: message.source_id, deleted: true })
          raw_message[:key][:id] = 'outgoing_echo_removal'
          raw_message[:key][:fromMe] = true
          raw_message[:message] = {
            reactionMessage: {
              key: { remoteJid: '12345678@lid', fromMe: true, id: 'msg_123' },
              text: ''
            }
          }
          described_class.new(inbox: inbox, params: params).perform

          existing_reaction.reload
          expect(existing_reaction.content).to eq('')
          expect(existing_reaction.content_attributes['deleted']).to be(true)
        end
      end

      context 'when message type is image' do
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '12345678@lid', remoteJidAlt: '5511998765432@s.whatsapp.net', fromMe: false,
                         addressingMode: 'lid' },
                  message: { imageMessage: { caption: 'Hello from Baileys', mimetype: 'image/png' } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates the message with caption' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          expect(message.content).to eq('Hello from Baileys')
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last
          expect(attachment.file_type).to eq('image')
          expect(attachment.file.filename.to_s).to eq("image_msg_123_#{Time.current.strftime('%Y%m%d')}.png")
          expect(attachment.file.content_type).to eq('image/png')
        end

        it 'sets message as unsupported and logs error if attachment download fails' do
          allow(Down).to receive(:download).and_raise(Down::ResponseError.new('Attachment not found'))
          allow(Rails.logger).to receive(:error).with('Failed to download attachment for message msg_123: Attachment not found')

          described_class.new(inbox: inbox, params: params).perform

          expect(Rails.logger).to have_received(:error)
          message = inbox.conversations.last.messages.last
          expect(message).to be_present
          expect(message.is_unsupported).to be(true)
        end
      end

      context 'when message type is video' do
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '12345678@lid', remoteJidAlt: '5511998765432@s.whatsapp.net', fromMe: false,
                         addressingMode: 'lid' },
                  message: { videoMessage: { caption: 'Hello from Baileys', mimetype: 'video/mp4' } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates the message with caption' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last

          expect(message).to be_present
          expect(message.content).to eq('Hello from Baileys')
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last
          expect(attachment.file_type).to eq('video')
          expect(attachment.file.filename.to_s).to eq("video_msg_123_#{Time.current.strftime('%Y%m%d')}.mp4")
          expect(attachment.file.content_type).to eq('video/mp4')
        end
      end

      context 'when message type is file' do
        let(:filename) { 'file.pdf' }
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '12345678@lid', remoteJidAlt: '5511998765432@s.whatsapp.net', fromMe: false,
                         addressingMode: 'lid' },
                  message: { documentMessage: { fileName: filename } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last
          expect(attachment.file_type).to eq('file')
          expect(attachment.file.filename.to_s).to eq(filename)
          expect(attachment.file.content_type).to eq('application/pdf')
        end

        it 'creates the message with caption' do
          params[:data][:messages].first[:message] = {
            documentWithCaptionMessage: {
              message: {
                documentMessage: {
                  fileName: filename,
                  caption: 'Hello from Baileys'
                }
              }
            }
          }
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          expect(message).to be_present
          expect(message.content).to eq('Hello from Baileys')
        end
      end

      context 'when message type is audio' do
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '12345678@lid', remoteJidAlt: '5511998765432@s.whatsapp.net', fromMe: false,
                         addressingMode: 'lid' },
                  message: { audioMessage: { mimetype: 'audio/opus' } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last
          expect(attachment.file_type).to eq('audio')
          expect(attachment.file.filename.to_s).to eq("audio_msg_123_#{Time.current.strftime('%Y%m%d')}.opus")
          # audio/ogg, not the audio/opus the payload declares: the container is Ogg either way and
          # audio/ogg is the type registered for it, so this is what makes the note forwardable.
          # WhatsApp Cloud rejects audio/opus with 131053, and only classifies audio/ogg as voice.
          expect(attachment.file.content_type).to eq('audio/ogg')
        end
      end

      context 'when message type is sticker' do
        let(:params) do
          {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [
                {
                  key: { id: 'msg_123', remoteJid: '12345678@lid', remoteJidAlt: '5511998765432@s.whatsapp.net', fromMe: false,
                         addressingMode: 'lid' },
                  message: { stickerMessage: { mimetype: 'image/png' } },
                  pushName: 'John Doe'
                }
              ]
            }
          }
        end

        it 'creates message attachment' do
          stub_download

          described_class.new(inbox: inbox, params: params).perform

          message = inbox.conversations.last.messages.last
          attachment = message.attachments.last
          expect(attachment.file_type).to eq('image')
          expect(attachment.file.filename.to_s).to eq("image_msg_123_#{Time.current.strftime('%Y%m%d')}.png")
          expect(attachment.file.content_type).to eq('image/png')
        end
      end

      context 'when processing multiple messages' do
        it 'creates separate contacts and conversations for each message' do
          raw_message1 = {
            key: { id: 'msg_123', remoteJid: '5511998765432@s.whatsapp.net', remoteJidAlt: '12345678@lid', fromMe: false, addressingMode: 'pn' },
            pushName: 'John Doe',
            messageTimestamp: timestamp,
            message: { conversation: 'Hello from Baileys' }
          }
          raw_message2 = {
            key: { id: 'msg_124', remoteJid: '5511987654321@s.whatsapp.net', remoteJidAlt: '87654321@lid', fromMe: false, addressingMode: 'pn' },
            pushName: 'Jane Doe',
            messageTimestamp: timestamp,
            message: { conversation: 'Hello from another user' }
          }
          params = {
            webhookVerifyToken: webhook_verify_token,
            event: 'messages.upsert',
            data: {
              type: 'notify',
              messages: [raw_message1, raw_message2]
            }
          }

          described_class.new(inbox: inbox, params: params).perform

          conversations = inbox.conversations.order(:created_at)
          expect(conversations.count).to eq(2)

          first_conversation = conversations.first
          first_message = first_conversation.messages.last
          expect(first_conversation.contact.name).to eq('John Doe')
          expect(first_message.source_id).to eq('msg_123')
          expect(first_message.content).to eq('Hello from Baileys')

          second_conversation = conversations.second
          second_message = second_conversation.messages.last
          expect(second_conversation.contact.name).to eq('Jane Doe')
          expect(second_message.source_id).to eq('msg_124')
          expect(second_message.content).to eq('Hello from another user')
        end
      end

      context 'when jid type is lid' do
        it 'processes the message with phone number from addressingMode pn' do
          raw_message[:key][:remoteJid] = '5511998765432@s.whatsapp.net'
          raw_message[:key][:remoteJidAlt] = '12345678@lid'
          raw_message[:key][:addressingMode] = 'pn'

          described_class.new(inbox: inbox, params: params).perform

          conversation = inbox.conversations.last
          message = conversation.messages.last

          expect(message).to be_present
          expect(conversation.contact.phone_number).to eq('+5511998765432')
        end
      end

      it 'skips message if LID cannot be extracted' do
        raw_message[:key][:remoteJid] = 'invalid_jid'
        raw_message[:key][:remoteJidAlt] = nil
        raw_message[:key][:addressingMode] = 'lid'

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.conversations).to be_empty
      end

      context 'when handling LID field' do
        it 'creates contact with LID as source_id and identifier' do
          described_class.new(inbox: inbox, params: params).perform

          contact = inbox.contacts.last
          contact_inbox = inbox.contact_inboxes.last

          expect(contact.identifier).to eq('12345678@lid')
          expect(contact_inbox.source_id).to eq('12345678')
        end

        it 'updates existing contact_inbox from phone to LID source_id' do
          contact = create(:contact, account: inbox.account, phone_number: '+5511998765432', identifier: nil)
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5511998765432')

          described_class.new(inbox: inbox, params: params).perform

          contact_inbox = inbox.contact_inboxes.find_by(contact: contact)
          expect(contact_inbox.source_id).to eq('12345678')
          expect(contact.reload.identifier).to eq('12345678@lid')
          expect(contact.phone_number).to eq('+5511998765432')
        end

        it 'reuses a contact saved with the Brazilian ninth digit when the reply arrives without it' do
          # Regression: the agent saved the number with the ninth digit and outbound
          # normalization was skipped; the reply delivers the canonical number without
          # it and must not spawn a duplicate contact in a new conversation.
          raw_message[:key][:remoteJidAlt] = '551198765432@s.whatsapp.net'
          contact = create(:contact, account: inbox.account, phone_number: '+5511998765432', identifier: nil)
          contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5511998765432')
          conversation = create(:conversation, inbox: inbox, contact: contact, contact_inbox: contact_inbox)

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.not_to change(Contact, :count)

          expect(contact_inbox.reload.source_id).to eq('12345678')
          expect(contact.reload.identifier).to eq('12345678@lid')
          expect(contact.phone_number).to eq('+551198765432')
          expect(conversation.reload.messages.last.content).to eq('Hello from Baileys')
        end

        it 'does not update contact_inbox if source_id is already LID' do
          contact = create(:contact, account: inbox.account, phone_number: '+5511998765432', identifier: '12345678@lid')
          contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact_inbox.reload.source_id).to eq('12345678')
          expect(contact.reload.identifier).to eq('12345678@lid')
        end
      end

      context 'when updating contact information' do
        it 'updates contact phone number if blank' do
          contact = create(:contact, account: inbox.account, phone_number: nil, identifier: '12345678@lid')
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact.reload.phone_number).to eq('+5511998765432')
        end

        it 'updates contact name if it matches phone number' do
          contact = create(:contact, account: inbox.account, name: '5511998765432', phone_number: '+5511998765432', identifier: '12345678@lid')
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact.reload.name).to eq('John Doe')
        end

        it 'updates contact name when stored name is a phone variant missing the Brazilian 9' do
          # The contact was registered without the "9"; phone normalization later aligned
          # phone_number to the canonical number, but the name kept the stale digits.
          contact = create(:contact, account: inbox.account, name: '551198765432', phone_number: '+5511998765432', identifier: '12345678@lid')
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact.reload.name).to eq('John Doe')
        end

        it 'updates contact name when stored name is a phone number with a leading +' do
          contact = create(:contact, account: inbox.account, name: '+5511998765432', phone_number: '+5511998765432', identifier: '12345678@lid')
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact.reload.name).to eq('John Doe')
        end

        it 'updates contact name if it matches LID source_id' do
          contact = create(:contact, account: inbox.account, name: '12345678', phone_number: '+5511998765432', identifier: '12345678@lid')
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact.reload.name).to eq('John Doe')
        end

        it 'updates contact name if it matches identifier' do
          contact = create(:contact, account: inbox.account, name: '12345678@lid', phone_number: '+5511998765432', identifier: '12345678@lid')
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact.reload.name).to eq('John Doe')
        end

        it 'does not update contact name if it is different from phone number, source_id, and identifier' do
          contact = create(:contact, account: inbox.account, name: 'Existing Name', phone_number: '+5511998765432', identifier: '12345678@lid')
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact.reload.name).to eq('Existing Name')
        end

        it 'does not overwrite a digit-only name that is not this contact phone or LID' do
          contact = create(:contact, account: inbox.account, name: '99887766', phone_number: '+5511998765432', identifier: '12345678@lid')
          create(:contact_inbox, inbox: inbox, contact: contact, source_id: '12345678')

          described_class.new(inbox: inbox, params: params).perform

          expect(contact.reload.name).to eq('99887766')
        end
      end
    end

    context 'when processing messages.update event' do
      let(:conversation) do
        agent = create(:user, account: inbox.account, role: :agent)
        contact = create(:contact, account: inbox.account)
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact)
        create(:conversation, inbox: inbox, contact_inbox: contact_inbox, assignee_id: agent.id)
      end
      let!(:message) { create(:message, inbox: inbox, conversation: conversation, source_id: 'msg_123', status: 'sent') }
      let(:update_payload) { { key: { id: 'msg_123' }, update: { status: 3 } } }
      let(:params) do
        {
          webhookVerifyToken: webhook_verify_token,
          event: 'messages.update',
          data: [update_payload]
        }
      end

      context 'when message is not found' do
        it 'raises MessageNotFoundError' do
          update_payload[:key][:id] = 'no_message_id'

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.to(raise_error { |error| expect(error.class.name).to eq('Whatsapp::BaileysHandlers::MessagesUpdate::MessageNotFoundError') })
        end
      end

      context 'when is a status update' do
        it 'updates the message status' do
          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('delivered')
        end

        it 'updates conversation agent_last_seen_at and assignee_last_seen_at' do
          freeze_time
          update_payload[:key][:fromMe] = false
          update_payload[:update][:status] = 4

          conversation.update!(agent_last_seen_at: 1.day.ago, assignee_last_seen_at: 1.day.ago)

          described_class.new(inbox: inbox, params: params).perform

          expect(conversation.reload.agent_last_seen_at).to eq(Time.current)
          expect(conversation.assignee_last_seen_at).to eq(Time.current)
        end

        # The provider echoes back the receipt this app sent, and taking it for a device of
        # this account clears the unread badge of a conversation nobody here has opened.
        it 'leaves the markers alone when the read receipt is our own echoed back' do
          update_payload[:key][:fromMe] = false
          update_payload[:update][:status] = 4
          conversation.update!(agent_last_seen_at: 1.day.ago, assignee_last_seen_at: 1.day.ago)
          Whatsapp::SelfReadReceipts.record(conversation, [message])

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.to(not_change { conversation.reload.agent_last_seen_at })

          Redis::Alfred.delete(Whatsapp::SelfReadReceipts.key(conversation, message.source_id))
        end

        # `messages.update` is a batch, so a lookup per update would put a Redis round trip on
        # each one; the ids of the whole webhook are asked for once, as the session handler does.
        it 'reads the acknowledged ids once for the whole batch' do
          second = create(:message, inbox: inbox, conversation: conversation, source_id: 'msg_124', status: 'sent')
          params[:data] = [
            { key: { id: message.source_id, fromMe: false }, update: { status: 4 } },
            { key: { id: second.source_id, fromMe: false }, update: { status: 4 } }
          ]
          allow(Whatsapp::SelfReadReceipts).to receive(:acknowledged).and_call_original

          described_class.new(inbox: inbox, params: params).perform

          expect(Whatsapp::SelfReadReceipts).to have_received(:acknowledged).with(conversation, %w[msg_123 msg_124]).once
        end

        it "does not downgrade a 'read' message to delivered" do
          message.update!(status: 'read')

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('read')
        end

        it 'logs warning for unsupported played status' do
          update_payload[:update][:status] = 5

          allow(Rails.logger).to receive(:warn).with('Baileys unsupported message update status: PLAYED(5)').and_return(true)

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.not_to raise_error

          expect(Rails.logger).to have_received(:warn)
        end

        it 'logs warning for unsupported status' do
          update_payload[:update][:status] = 6

          allow(Rails.logger).to receive(:warn).with('Baileys unsupported message update status: 6').and_return(true)

          expect do
            described_class.new(inbox: inbox, params: params).perform
          end.not_to raise_error

          expect(Rails.logger).to have_received(:warn)
        end

        it 'marks the message as failed and stores the stub description with code' do
          update_payload[:update][:status] = 0
          update_payload[:update][:messageStubParameters] = ['463', 'Your account has been restricted']

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('failed')
          expect(message.external_error).to eq('Your account has been restricted (463)')
        end

        it 'falls back to a generic message when only the error code is present on failure' do
          update_payload[:update][:status] = 0
          update_payload[:update][:messageStubParameters] = ['429']

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('failed')
          expect(message.external_error).to eq('WhatsApp error 429')
        end

        it 'leaves external_error blank on failure when stub parameters are absent' do
          update_payload[:update][:status] = 0

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('failed')
          expect(message.external_error).to be_blank
        end

        { 1 => 'sent', 2 => 'sent', 3 => 'delivered', 4 => 'read' }.each do |baileys_status, status|
          it "clears the external_error when a failed message moves to #{status} (Baileys #{baileys_status})" do
            message.update!(status: 'failed', external_error: 'WhatsApp error 479')
            update_payload[:update][:status] = baileys_status

            described_class.new(inbox: inbox, params: params).perform

            expect(message.reload.status).to eq(status)
            expect(message.external_error).to be_nil
          end
        end

        it 'keeps the external_error of a failed message on an update that maps to no status' do
          message.update!(status: 'failed', external_error: 'WhatsApp error 479')
          update_payload[:update][:status] = 5

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('failed')
          expect(message.external_error).to eq('WhatsApp error 479')
        end

        it "does not mark a 'read' message as failed" do
          message.update!(status: 'read')
          update_payload[:update][:status] = 0
          update_payload[:update][:messageStubParameters] = ['479']

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.status).to eq('read')
          expect(message.external_error).to be_nil
        end
      end

      context 'when is a content update' do
        it 'updates the message content' do
          original_content = message.content
          update_payload[:update] = { message: { editedMessage: { message: { conversation: 'New message content' } } } }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('New message content')
          expect(message.is_edited).to be(true)
          expect(message.previous_content).to eq(original_content)
        end

        it 'records the edit timestamp in milliseconds so a later update can be ordered against it' do
          update_payload[:update] = {
            message: { editedMessage: { message: { conversation: 'New message content' } } },
            messageTimestamp: 1_700_000_000
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.edited_at).to eq(1_700_000_000_000)
        end

        # A force restart or a cluster handoff leaves the discarded connection
        # draining its webhooks while the replacement already handles new events,
        # so an older edit retrying on the old one can land after a newer one.
        it 'ignores an edit older than the one already applied' do
          message.update!(edited_at: 1_700_000_060_000)
          update_payload[:update] = {
            message: { editedMessage: { message: { conversation: 'Stale message content' } } },
            messageTimestamp: 1_700_000_000
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).not_to eq('Stale message content')
          expect(message.is_edited).to be_falsey
        end

        it 'applies an edit newer than the one already applied' do
          message.update!(edited_at: 1_700_000_000_000)
          update_payload[:update] = {
            message: { editedMessage: { message: { conversation: 'Newer message content' } } },
            messageTimestamp: 1_700_000_060
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('Newer message content')
          expect(message.edited_at).to eq(1_700_000_060_000)
        end

        # Equal timestamps carry no order to respect, and WhatsApp stamps edits in
        # whole seconds.
        it 'applies an edit stamped in the same second as the one already applied' do
          message.update!(edited_at: 1_700_000_000_000)
          update_payload[:update] = {
            message: { editedMessage: { message: { conversation: 'Same second content' } } },
            messageTimestamp: 1_700_000_000
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('Same second content')
        end

        # Refusing it would drop the edit outright, which is worse than applying
        # it out of order.
        it 'applies an edit that carries no timestamp' do
          message.update!(edited_at: 1_700_000_060_000)
          update_payload[:update] = { message: { editedMessage: { message: { conversation: 'Undated content' } } } }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('Undated content')
        end

        # Writing nil would erase what a later out-of-order edit is checked against.
        it 'keeps the stored timestamp when an undated edit is applied' do
          message.update!(edited_at: 1_700_000_060_000)
          update_payload[:update] = { message: { editedMessage: { message: { conversation: 'Undated content' } } } }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.edited_at).to eq(1_700_000_060_000)
        end

        # A protobuf 64-bit field reaches us either as a number or as a { low, high }
        # hash, and calling to_i on the hash would raise and drop the edit.
        it 'reads a timestamp that arrives as a structured protobuf long' do
          update_payload[:update] = {
            message: { editedMessage: { message: { conversation: 'Structured stamp' } } },
            messageTimestamp: { 'low' => 1_700_000_000, 'high' => 0, 'unsigned' => true }
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('Structured stamp')
          expect(message.edited_at).to eq(1_700_000_000_000)
        end

        # An edit that clears an image caption sends an empty string, and dropping it
        # would leave the old caption on screen.
        it 'applies an edit that clears the content' do
          update_payload[:update] = {
            message: { editedMessage: { message: { imageMessage: { caption: '' } } } },
            messageTimestamp: 1_700_000_000
          }

          described_class.new(inbox: inbox, params: params).perform

          expect(message.reload.content).to eq('')
          expect(message.is_edited).to be(true)
        end
      end
    end

    context 'when processing message-receipt.update event' do
      let(:conversation) do
        agent = create(:user, account: inbox.account, role: :agent)
        contact = create(:contact, account: inbox.account)
        contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact)
        create(:conversation, inbox: inbox, contact_inbox: contact_inbox, assignee_id: agent.id)
      end
      let!(:message) { create(:message, inbox: inbox, conversation: conversation, source_id: '123ABCDE1234567', status: 'sent') }
      let(:receipt_payload) do
        {
          key: { remoteJid: '123456789123456789@g.us', id: '123ABCDE1234567', fromMe: true,
                 participant: '12345678@lid' },
          receipt: receipt_data
        }
      end
      let(:receipt_data) { { userJid: '12345678@lid', receiptTimestamp: 1_772_056_268 } }
      let(:params) do
        {
          webhookVerifyToken: webhook_verify_token,
          event: 'message-receipt.update',
          data: [receipt_payload]
        }
      end

      it 'updates message from sent to delivered on receiptTimestamp' do
        described_class.new(inbox: inbox, params: params).perform

        expect(message.reload.status).to eq('delivered')
      end

      it 'ignores readTimestamp and does not update status' do
        receipt_data.replace(userJid: '12345678@lid', readTimestamp: 1_772_056_497)

        described_class.new(inbox: inbox, params: params).perform

        expect(message.reload.status).to eq('sent')
      end

      it 'does not downgrade a delivered message on receiptTimestamp' do
        message.update!(status: 'delivered')

        described_class.new(inbox: inbox, params: params).perform

        expect(message.reload.status).to eq('delivered')
      end

      it 'clears the external_error when a failed message is delivered' do
        message.update!(status: 'failed', external_error: 'WhatsApp error 479')

        described_class.new(inbox: inbox, params: params).perform

        expect(message.reload.status).to eq('delivered')
        expect(message.external_error).to be_nil
      end

      it 'does not downgrade a read message on receiptTimestamp' do
        message.update!(status: 'read')

        described_class.new(inbox: inbox, params: params).perform

        expect(message.reload.status).to eq('read')
      end

      it 'does not raise error when message is not found' do
        receipt_payload[:key][:id] = 'NONEXISTENT_MSG_ID'

        expect { described_class.new(inbox: inbox, params: params).perform }.not_to raise_error
      end
    end
  end

  def format_message_source_key(message_id)
    format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{message_id}")
  end

  def stub_download
    allow(Down).to receive(:download)
      .with('https://baileys.api/media/msg_123', headers: inbox.channel.api_headers)
      .and_return(StringIO.new('Media data'))
  end

  def stub_profile_pic_fetch(url = nil)
    stub_request(:get, /profile-picture-url/)
      .to_return(
        status: 200,
        body: { data: { profilePictureUrl: url } }.to_json
      )
  end
end
