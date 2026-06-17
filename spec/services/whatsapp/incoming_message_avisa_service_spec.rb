# frozen_string_literal: true

require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS
RSpec.describe Whatsapp::IncomingMessageAvisaService do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

  subject(:service) { described_class.new(inbox: inbox, params: {}) }

  describe '#find_or_create_conversation' do
    context 'when the inbox locks to a single conversation' do
      let(:inbox) { create(:inbox, account: account, lock_to_single_conversation: true) }

      it 'reuses the last conversation even when it is resolved, reopening it' do
        resolved = create(:conversation, account: account, inbox: inbox,
                                         contact: contact, contact_inbox: contact_inbox,
                                         status: :resolved)

        result = service.send(:find_or_create_conversation, contact_inbox)

        expect(result.id).to eq(resolved.id)
        expect(result.reload.status).to eq('open')
      end

      it 'reuses an already-open conversation without touching its status' do
        open_conversation = create(:conversation, account: account, inbox: inbox,
                                                  contact: contact, contact_inbox: contact_inbox,
                                                  status: :open)

        result = service.send(:find_or_create_conversation, contact_inbox)

        expect(result.id).to eq(open_conversation.id)
        expect(result.status).to eq('open')
      end

      it 'creates a conversation when the contact has none' do
        expect do
          result = service.send(:find_or_create_conversation, contact_inbox)
          expect(result.contact_inbox_id).to eq(contact_inbox.id)
        end.to change(Conversation, :count).by(1)
      end
    end

    context 'when the inbox does not lock to a single conversation' do
      let(:inbox) { create(:inbox, account: account, lock_to_single_conversation: false) }

      it 'ignores a resolved conversation and creates a new one (legacy behaviour)' do
        create(:conversation, account: account, inbox: inbox,
                              contact: contact, contact_inbox: contact_inbox,
                              status: :resolved)

        expect do
          service.send(:find_or_create_conversation, contact_inbox)
        end.to change(Conversation, :count).by(1)
      end

      it 'reuses an open conversation' do
        open_conversation = create(:conversation, account: account, inbox: inbox,
                                                  contact: contact, contact_inbox: contact_inbox,
                                                  status: :open)

        result = service.send(:find_or_create_conversation, contact_inbox)

        expect(result.id).to eq(open_conversation.id)
      end
    end
  end
end
