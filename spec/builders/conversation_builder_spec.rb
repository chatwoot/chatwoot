require 'rails_helper'

describe ConversationBuilder do
  let(:account) { create(:account) }
  let!(:sms_channel) { create(:channel_sms, account: account) }
  let!(:api_channel) { create(:channel_api, account: account) }
  let!(:sms_inbox) { create(:inbox, channel: sms_channel, account: account) }
  let!(:api_inbox) { create(:inbox, channel: api_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_sms_inbox) { create(:contact_inbox, contact: contact, inbox: sms_inbox) }
  let(:contact_api_inbox) { create(:contact_inbox, contact: contact, inbox: api_inbox) }

  describe '#perform' do
    it 'creates sms conversation' do
      conversation = described_class.new(
        contact_inbox: contact_sms_inbox,
        params: {}
      ).perform

      expect(conversation.contact_inbox_id).to eq(contact_sms_inbox.id)
    end

    it 'creates api conversation' do
      conversation = described_class.new(
        contact_inbox: contact_api_inbox,
        params: {}
      ).perform

      expect(conversation.contact_inbox_id).to eq(contact_api_inbox.id)
    end

    context 'when lock_to_single_conversation is true for sms inbox' do
      before do
        sms_inbox.update!(lock_to_single_conversation: true)
      end

      it 'creates sms conversation when existing conversation is not present' do
        conversation = described_class.new(
          contact_inbox: contact_sms_inbox,
          params: {}
        ).perform

        expect(conversation.contact_inbox_id).to eq(contact_sms_inbox.id)
      end

      it 'returns last from existing sms conversations when existing conversation is not present' do
        create(:conversation, contact_inbox: contact_sms_inbox)
        existing_conversation = create(:conversation, contact_inbox: contact_sms_inbox)
        conversation = described_class.new(
          contact_inbox: contact_sms_inbox,
          params: {}
        ).perform

        expect(conversation.id).to eq(existing_conversation.id)
      end
    end

    context 'when lock_to_single_conversation is true for api inbox' do
      before do
        api_inbox.update!(lock_to_single_conversation: true)
      end

      it 'creates conversation when existing api conversation is not present' do
        conversation = described_class.new(
          contact_inbox: contact_api_inbox,
          params: {}
        ).perform

        expect(conversation.contact_inbox_id).to eq(contact_api_inbox.id)
      end

      it 'returns last from existing api conversations when existing conversation is not present' do
        create(:conversation, contact_inbox: contact_api_inbox)
        existing_conversation = create(:conversation, contact_inbox: contact_api_inbox)
        conversation = described_class.new(
          contact_inbox: contact_api_inbox,
          params: {}
        ).perform

        expect(conversation.id).to eq(existing_conversation.id)
      end
    end

    context 'when allow_messages_after_resolved is enabled and lock_to_single_conversation is disabled' do
      it 'reuses the last non-resolved conversation for the contact inbox' do
        create(:conversation, contact_inbox: contact_sms_inbox, status: :resolved)
        open_conversation = create(:conversation, contact_inbox: contact_sms_inbox, status: :open)

        conversation = described_class.new(contact_inbox: contact_sms_inbox, params: {}).perform

        expect(conversation.id).to eq(open_conversation.id)
      end

      it 'creates a new conversation when every existing conversation is resolved' do
        create(:conversation, contact_inbox: contact_sms_inbox, status: :resolved)

        conversation = described_class.new(contact_inbox: contact_sms_inbox, params: {}).perform

        expect(conversation.status).to eq('open')
        expect(conversation.contact_inbox_id).to eq(contact_sms_inbox.id)
      end
    end

    context 'when allow_messages_after_resolved is disabled' do
      before { sms_inbox.update!(allow_messages_after_resolved: false) }

      it 'creates a new conversation even when a non-resolved conversation exists' do
        existing = create(:conversation, contact_inbox: contact_sms_inbox, status: :open)

        conversation = described_class.new(contact_inbox: contact_sms_inbox, params: {}).perform

        expect(conversation.id).not_to eq(existing.id)
      end
    end
  end
end
