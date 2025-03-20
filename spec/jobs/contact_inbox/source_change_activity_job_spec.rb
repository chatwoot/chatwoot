require 'rails_helper'

RSpec.describe ContactInbox::SourceChangeActivityJob do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:previous_source_id) { 'old_id' }
  let(:current_source_id) { 'new_id' }

  describe '#perform' do
    context 'when inbox is email' do
      let(:channel) { create(:channel_email, account: account) }
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: channel.inbox) }
      let(:conversation) { create(:conversation, contact: contact, inbox: channel.inbox, account: account, contact_inbox: contact_inbox) }

      it 'creates activity message with email change text' do
        expected_message = I18n.t(
          'contact_inboxes.source_change.email_changed',
          previous: previous_source_id,
          current: current_source_id
        )

        expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(
          conversation,
          account_id: account.id,
          inbox_id: channel.inbox.id,
          message: expected_message,
          message_type: :activity
        )

        described_class.perform_now(contact_inbox.id, previous_source_id, current_source_id)
      end
    end

    context 'when inbox is whatsapp' do
      let(:channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: channel.inbox) }
      let(:conversation) { create(:conversation, contact: contact, inbox: channel.inbox, account: account, contact_inbox: contact_inbox) }

      it 'creates activity message with phone number change text' do
        expected_message = I18n.t('contact_inboxes.source_change.phone_number_changed',
                                  previous: previous_source_id,
                                  current: current_source_id)

        expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(
          conversation,
          account_id: account.id,
          inbox_id: channel.inbox.id,
          message: expected_message,
          message_type: :activity
        )

        described_class.perform_now(contact_inbox.id, previous_source_id, current_source_id)
      end
    end

    context 'when inbox is of other type' do
      let(:channel) { create(:channel_api, account: account) }
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: channel.inbox) }
      let(:conversation) { create(:conversation, contact: contact, inbox: channel.inbox, account: account, contact_inbox: contact_inbox) }

      it 'creates activity message with generic identifier change text' do
        expected_message = I18n.t('contact_inboxes.source_change.identifier_changed',
                                  previous: previous_source_id,
                                  current: current_source_id)

        expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(
          conversation,
          account_id: account.id,
          inbox_id: channel.inbox.id,
          message: expected_message,
          message_type: :activity
        )

        described_class.perform_now(contact_inbox.id, previous_source_id, current_source_id)
      end
    end

    context 'when multiple conversations exist' do
      let(:channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: channel.inbox) }
      let(:conversation) { create(:conversation, contact: contact, inbox: channel.inbox, account: account, contact_inbox: contact_inbox) }
      let(:conversation2) { create(:conversation, contact: contact, inbox: channel.inbox, account: account, contact_inbox: contact_inbox) }
      let(:conversation3) { create(:conversation, contact: contact, inbox: channel.inbox, account: account) }

      it 'creates activity message for each conversation' do
        expected_message = I18n.t('contact_inboxes.source_change.phone_number_changed',
                                  previous: previous_source_id,
                                  current: current_source_id)

        expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(
          conversation,
          account_id: account.id,
          inbox_id: channel.inbox.id,
          message: expected_message,
          message_type: :activity
        )

        expect(Conversations::ActivityMessageJob).to receive(:perform_later).with(
          conversation2,
          account_id: account.id,
          inbox_id: channel.inbox.id,
          message: expected_message,
          message_type: :activity
        )

        expect(Conversations::ActivityMessageJob).not_to receive(:perform_later).with(
          conversation3,
          account_id: account.id,
          inbox_id: channel.inbox.id,
          message: expected_message,
          message_type: :activity
        )

        described_class.perform_now(contact_inbox.id, previous_source_id, current_source_id)
      end
    end
  end
end
