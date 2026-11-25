# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactInbox do
  describe 'pubsub_token' do
    let(:contact_inbox) { create(:contact_inbox) }

    it 'gets created on object create' do
      obj = contact_inbox
      expect(obj.pubsub_token).not_to be_nil
    end

    it 'does not get updated on object update' do
      obj = contact_inbox
      old_token = obj.pubsub_token
      obj.update!(source_id: '234234323')
      expect(obj.pubsub_token).to eq(old_token)
    end

    it 'backfills pubsub_token on call for older objects' do
      obj = create(:contact_inbox)
      # to replicate an object with out pubsub_token
      # rubocop:disable Rails/SkipsModelValidations
      obj.update_column(:pubsub_token, nil)
      # rubocop:enable Rails/SkipsModelValidations

      obj.reload

      # ensure the column is nil in database
      expect(described_class.where(id: obj.id).pick(:pubsub_token)).to be_nil

      new_token = obj.pubsub_token
      obj.update!(source_id: '234234323')
      # the generated token shoul be persisted in db
      expect(obj.pubsub_token).to eq(new_token)
    end
  end

  describe 'validations' do
    context 'when source_id' do
      it 'allows source_id longer than 255 characters for channels without format restrictions' do
        long_source_id = 'a' * 300
        email_inbox = create(:inbox, channel: create(:channel_email))
        contact = create(:contact, account: email_inbox.account)
        contact_inbox = build(:contact_inbox, contact: contact, inbox: email_inbox, source_id: long_source_id)

        expect(contact_inbox.valid?).to be(true)
        expect { contact_inbox.save! }.not_to raise_error
        expect(contact_inbox.reload.source_id).to eq(long_source_id)
        expect(contact_inbox.source_id.length).to eq(300)
      end

      it 'validates whatsapp channel source_id' do
        whatsapp_inbox = create(:channel_whatsapp, sync_templates: false, validate_provider_config: false).inbox
        contact = create(:contact)
        valid_source_id = build(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: '1234567890')
        valid_bsuid_source_id = build(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'IN.2081978709342942')
        valid_parent_bsuid_source_id = build(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'IN.ENT.9081726354')
        ci_character_in_source_id = build(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: '1234567890aaa')
        ci_plus_in_source_id = build(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: '+1234567890')
        expect(valid_source_id.valid?).to be(true)
        expect(valid_bsuid_source_id.valid?).to be(true)
        expect(valid_parent_bsuid_source_id.valid?).to be(true)
        expect(ci_character_in_source_id.valid?).to be(false)
        expect(ci_character_in_source_id.errors.full_messages).to eq(
          ["Source invalid source id for whatsapp inbox. valid Regex #{RegexHelper::WHATSAPP_CHANNEL_REGEX}"]
        )
        expect(ci_plus_in_source_id.valid?).to be(false)
        expect(ci_plus_in_source_id.errors.full_messages).to eq(
          ["Source invalid source id for whatsapp inbox. valid Regex #{RegexHelper::WHATSAPP_CHANNEL_REGEX}"]
        )
      end

      it 'validates twilio sms channel source_id' do
        twilio_sms_inbox = create(:channel_twilio_sms).inbox
        contact = create(:contact)
        valid_source_id = build(:contact_inbox, contact: contact, inbox: twilio_sms_inbox, source_id: '+1234567890')
        ci_character_in_source_id = build(:contact_inbox, contact: contact, inbox: twilio_sms_inbox, source_id: '+1234567890aaa')
        ci_without_plus_in_source_id = build(:contact_inbox, contact: contact, inbox: twilio_sms_inbox, source_id: '1234567890')
        expect(valid_source_id.valid?).to be(true)
        expect(ci_character_in_source_id.valid?).to be(false)
        expect(ci_character_in_source_id.errors.full_messages).to eq(
          ["Source invalid source id for twilio sms inbox. valid Regex #{RegexHelper::TWILIO_CHANNEL_SMS_REGEX}"]
        )
        expect(ci_without_plus_in_source_id.valid?).to be(false)
        expect(ci_without_plus_in_source_id.errors.full_messages).to eq(
          ["Source invalid source id for twilio sms inbox. valid Regex #{RegexHelper::TWILIO_CHANNEL_SMS_REGEX}"]
        )
      end

      it 'validates twilio whatsapp channel source_id' do
        twilio_whatsapp_inbox = create(:channel_twilio_sms, medium: :whatsapp).inbox
        contact = create(:contact)
        valid_source_id = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox, source_id: 'whatsapp:+1234567890')
        valid_bsuid_source_id = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox, source_id: 'whatsapp:IN.2081978709342942')
        valid_parent_bsuid_source_id = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox, source_id: 'whatsapp:IN.ENT.9081726354')
        ci_character_in_source_id = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox, source_id: 'whatsapp:+1234567890aaa')
        ci_without_plus_in_source_id = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox, source_id: 'whatsapp:1234567890')
        expect(valid_source_id.valid?).to be(true)
        expect(valid_bsuid_source_id.valid?).to be(true)
        expect(valid_parent_bsuid_source_id.valid?).to be(true)
        expect(ci_character_in_source_id.valid?).to be(false)
        expect(ci_character_in_source_id.errors.full_messages).to eq(
          ["Source invalid source id for twilio whatsapp inbox. valid Regex #{RegexHelper::TWILIO_CHANNEL_WHATSAPP_REGEX}"]
        )
        expect(ci_without_plus_in_source_id.valid?).to be(false)
        expect(ci_without_plus_in_source_id.errors.full_messages).to eq(
          ["Source invalid source id for twilio whatsapp inbox. valid Regex #{RegexHelper::TWILIO_CHANNEL_WHATSAPP_REGEX}"]
        )
      end

      it 'rejects whatsapp BSUID source_id values longer than 128 alphanumeric characters' do
        whatsapp_inbox = create(:channel_whatsapp, sync_templates: false, validate_provider_config: false).inbox
        contact = create(:contact)
        contact_inbox = build(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: "IN.#{'1' * 129}")

        expect(contact_inbox.valid?).to be(false)
      end

      it 'rejects twilio whatsapp parent BSUID source_id values longer than 128 alphanumeric characters' do
        twilio_whatsapp_inbox = create(:channel_twilio_sms, medium: :whatsapp).inbox
        contact = create(:contact)
        contact_inbox = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox,
                                              source_id: "whatsapp:IN.ENT.#{'1' * 129}")

        expect(contact_inbox.valid?).to be(false)
      end
    end
  end

  # The "no WhatsApp" answer belongs to the phone that was looked up (fazer-ai/chatwoot#877).
  describe 'no-WhatsApp answer and the phone it was about' do
    let(:contact_inbox) { create(:contact_inbox, whatsapp_missing_checked_at: 1.hour.ago) }

    it 'is forgotten when the contact phone is corrected' do
      contact_inbox.contact.update!(phone_number: '+5585911112222')

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
    end

    it 'survives edits that leave the phone alone' do
      contact_inbox.contact.update!(name: 'Renamed')

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
    end

    # The banner reads the conversation, and a contact update only reaches the contacts store.
    it 'tells the dashboard about the conversations it changed' do
      conversation = create(:conversation, contact: contact_inbox.contact, contact_inbox: contact_inbox, inbox: contact_inbox.inbox)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      contact_inbox.contact.update!(phone_number: '+5585911112222')

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Events::Types::CONVERSATION_UPDATED, anything, hash_including(conversation: conversation))
    end

    # An older snapshot with an equal updated_at would be kept by the dashboard and bring the
    # warning back.
    it 'moves the conversation version forward with the change' do
      conversation = create(:conversation, contact: contact_inbox.contact, contact_inbox: contact_inbox, inbox: contact_inbox.inbox)
      conversation.update_column(:updated_at, 1.day.ago) # rubocop:disable Rails/SkipsModelValidations

      expect { contact_inbox.clear_whatsapp_missing! }.to(change { conversation.reload.updated_at })
    end

    it 'is forgotten when a merge moves the row under another contact' do
      base = create(:contact, account: contact_inbox.contact.account, phone_number: '+5585933334444')

      ContactMergeAction.new(account: base.account, base_contact: base, mergee_contact: contact_inbox.contact).perform

      expect(contact_inbox.reload.contact_id).to eq(base.id)
      expect(contact_inbox.whatsapp_missing_checked_at).to be_nil
    end
  end

  describe '#mark_whatsapp_missing_for!' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:contact_inbox) { create(:contact_inbox, inbox: channel.inbox, source_id: '558588246590') }
    let(:conversation) do
      create(:conversation, contact: contact_inbox.contact, contact_inbox: contact_inbox, inbox: contact_inbox.inbox)
    end

    # The reply's clear ran while nothing was flagged yet, and the evidence read came first.
    it 'drops the flag when a reply lands between reading the evidence and committing it' do
      phone = contact_inbox.contact.phone_number
      asked_at = 1.minute.ago
      reads = 0
      allow(contact_inbox).to receive(:whatsapp_presence_since?).and_wrap_original do |original, time|
        reads += 1
        next false if reads == 1

        original.call(time)
      end
      create(:message, conversation: conversation, inbox: channel.inbox, account: conversation.account, message_type: :incoming)

      contact_inbox.mark_whatsapp_missing_for!(phone, flag_before: nil, asked_at: asked_at)

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
    end

    # Sent while the provider was answering, delivered after the "no" was written.
    it 'yields to a receipt for a message sent during the lookup that arrives afterwards' do
      asked_at = 1.minute.ago
      message = create(:message, conversation: conversation, inbox: channel.inbox, account: conversation.account,
                                 message_type: :outgoing, status: :sent, created_at: 30.seconds.ago)
      Redis::Alfred.delete(described_class.whatsapp_receipt_key(contact_inbox.inbox_id, contact_inbox.contact_id))

      contact_inbox.mark_whatsapp_missing_for!(contact_inbox.contact.phone_number, flag_before: nil, asked_at: asked_at)
      message.update!(status: :delivered)

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
    end

    # Writing it only to undo it would flash the banner on every open thread.
    it 'does not write the flag at all when the evidence is already there' do
      create(:message, conversation: conversation, inbox: channel.inbox, account: conversation.account, message_type: :incoming)
      allow(contact_inbox).to receive(:broadcast_whatsapp_missing_change)

      contact_inbox.mark_whatsapp_missing_for!(contact_inbox.contact.phone_number, flag_before: nil, asked_at: 1.minute.ago)

      expect(contact_inbox).not_to have_received(:broadcast_whatsapp_missing_change)
    end

    it 'keeps the flag when no evidence arrives' do
      contact_inbox.mark_whatsapp_missing_for!(contact_inbox.contact.phone_number, flag_before: nil, asked_at: 1.minute.ago)

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
    end
  end

  describe '#broadcast_whatsapp_missing_change' do
    # A lookup is not a conversation update: automations and bots must not act on it.
    it 'reaches the dashboard and nothing else' do
      contact_inbox = create(:contact_inbox)
      create(:conversation, contact: contact_inbox.contact, contact_inbox: contact_inbox, inbox: contact_inbox.inbox)
      levels = []
      allow(Rails.configuration.dispatcher).to receive(:dispatch) do
        levels << [Import::SilentWrite.on?, Import::SilentWrite.announce?, Import::SilentWrite.archive?]
      end

      contact_inbox.broadcast_whatsapp_missing_change

      expect(levels).to eq([[true, true, false]])
    end

    # No message arrived, so the open thread must not jump to the bottom.
    it 'tags the update as a banner-only change' do
      contact_inbox = create(:contact_inbox)
      conversation = create(:conversation, contact: contact_inbox.contact, contact_inbox: contact_inbox, inbox: contact_inbox.inbox)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      contact_inbox.broadcast_whatsapp_missing_change

      metadata = { source: 'whatsapp_missing' }
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Events::Types::CONVERSATION_UPDATED, anything, hash_including(conversation: conversation, broadcast_metadata: metadata))
    end
  end

  describe '#whatsapp_presence_since?' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:contact_inbox) { create(:contact_inbox, inbox: channel.inbox, source_id: '558588246590') }
    let(:conversation) do
      create(:conversation, contact: contact_inbox.contact, contact_inbox: contact_inbox, inbox: contact_inbox.inbox)
    end
    let(:asked_at) { 1.minute.ago }

    def outgoing_message(status)
      create(:message, conversation: conversation, inbox: contact_inbox.inbox, account: conversation.account,
                       message_type: :outgoing, status: status)
    end

    it 'sees a receipt that came back after the question' do
      outgoing_message(:sent).update!(status: :delivered)

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(true)
    end

    it 'does not count a receipt older than the question' do
      outgoing_message(:sent).update!(status: :delivered)

      expect(contact_inbox.whatsapp_presence_since?(1.second.from_now)).to be(false)
    end

    it 'does not count a receipt for a message sent before the question' do
      create(:message, conversation: conversation, inbox: contact_inbox.inbox, account: conversation.account,
                       message_type: :outgoing, status: :sent, created_at: 2.minutes.ago).update!(status: :delivered)

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(false)
    end

    # Receipts come back out of order; an older send answered later must not hide a newer one.
    it 'keeps the newest send a receipt answered' do
      newer = outgoing_message(:sent)
      older = create(:message, conversation: conversation, inbox: contact_inbox.inbox, account: conversation.account,
                               message_type: :outgoing, status: :sent, created_at: 2.minutes.ago)
      newer.update!(status: :delivered)
      older.update!(status: :delivered)

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(true)
    end

    # A send from the paired phone comes back born delivered: nobody's phone answered it.
    it 'does not count an echo' do
      outgoing_message(:delivered)

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(false)
    end

    it 'does not count a receipt replayed by an import' do
      message = outgoing_message(:sent)
      Import::SilentWrite.wrap { message.update!(status: :delivered) }

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(false)
    end

    it 'sees a message the contact sent after the question' do
      create(:message, conversation: conversation, inbox: contact_inbox.inbox, account: conversation.account, message_type: :incoming)

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(true)
    end

    # WhatsApp stamps whole seconds, so a reply in the second the lookup started may be later.
    it 'counts a reply stamped in the second the question was asked' do
      asked = Time.current.change(usec: 400_000)
      travel_to(asked + 0.4.seconds) do
        create(:message, conversation: conversation, inbox: contact_inbox.inbox, account: conversation.account, message_type: :incoming,
                         content_attributes: { external_created_at: asked.to_i })
      end

      expect(contact_inbox.whatsapp_presence_since?(asked)).to be(true)
    end

    it 'sees a reply on another thread of the contact in the inbox' do
      sibling = create(:contact_inbox, contact: contact_inbox.contact, inbox: contact_inbox.inbox, source_id: '123456789012345')
      other = create(:conversation, contact: sibling.contact, contact_inbox: sibling, inbox: sibling.inbox)
      create(:message, conversation: other, inbox: sibling.inbox, account: other.account, message_type: :incoming)

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(true)
    end

    it 'sees a receipt on another thread of the contact in the inbox' do
      sibling = create(:contact_inbox, contact: contact_inbox.contact, inbox: contact_inbox.inbox, source_id: '123456789012345')
      other = create(:conversation, contact: sibling.contact, contact_inbox: sibling, inbox: sibling.inbox)
      create(:message, conversation: other, inbox: sibling.inbox, account: other.account, message_type: :outgoing, status: :sent)
        .update!(status: :delivered)

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(true)
    end

    # Written now, sent a year ago: history says nothing about the number today.
    it 'does not count an imported message sent before the question' do
      create(:message, conversation: conversation, inbox: contact_inbox.inbox, account: conversation.account, message_type: :incoming,
                       content_attributes: { external_created_at: 1.year.ago.to_i })

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(false)
    end

    # The server's acknowledgement is exactly what a number with no account still gets.
    it 'does not count a message that was only sent' do
      outgoing_message(:sent)

      expect(contact_inbox.whatsapp_presence_since?(asked_at)).to be(false)
    end
  end
end
