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
      obj.update(source_id: '234234323')
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
      results = ActiveRecord::Base.connection.execute('Select * from contact_inboxes;')
      expect(results.first['pubsub_token']).to be_nil

      new_token = obj.pubsub_token
      obj.update(source_id: '234234323')
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
        ci_character_in_source_id = build(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: '1234567890aaa')
        ci_plus_in_source_id = build(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: '+1234567890')
        expect(valid_source_id.valid?).to be(true)
        expect(ci_character_in_source_id.valid?).to be(false)
        expect(ci_character_in_source_id.errors.full_messages).to eq(
          ['Source invalid source id for whatsapp inbox. valid Regex (?-mix:^\\d{1,15}\\z)']
        )
        expect(ci_plus_in_source_id.valid?).to be(false)
        expect(ci_plus_in_source_id.errors.full_messages).to eq(
          ['Source invalid source id for whatsapp inbox. valid Regex (?-mix:^\\d{1,15}\\z)']
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
          ['Source invalid source id for twilio sms inbox. valid Regex (?-mix:^\\+\\d{1,15}\\z)']
        )
        expect(ci_without_plus_in_source_id.valid?).to be(false)
        expect(ci_without_plus_in_source_id.errors.full_messages).to eq(
          ['Source invalid source id for twilio sms inbox. valid Regex (?-mix:^\\+\\d{1,15}\\z)']
        )
      end

      it 'validates twilio whatsapp channel source_id' do
        twilio_whatsapp_inbox = create(:channel_twilio_sms, medium: :whatsapp).inbox
        contact = create(:contact)
        valid_source_id = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox, source_id: 'whatsapp:+1234567890')
        ci_character_in_source_id = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox, source_id: 'whatsapp:+1234567890aaa')
        ci_without_plus_in_source_id = build(:contact_inbox, contact: contact, inbox: twilio_whatsapp_inbox, source_id: 'whatsapp:1234567890')
        expect(valid_source_id.valid?).to be(true)
        expect(ci_character_in_source_id.valid?).to be(false)
        expect(ci_character_in_source_id.errors.full_messages).to eq(
          ['Source invalid source id for twilio whatsapp inbox. valid Regex (?-mix:^whatsapp:\\+\\d{1,15}\\z)']
        )
        expect(ci_without_plus_in_source_id.valid?).to be(false)
        expect(ci_without_plus_in_source_id.errors.full_messages).to eq(
          ['Source invalid source id for twilio whatsapp inbox. valid Regex (?-mix:^whatsapp:\\+\\d{1,15}\\z)']
        )
      end
    end
  end
end
