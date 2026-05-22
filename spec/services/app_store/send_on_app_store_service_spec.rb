# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppStore::SendOnAppStoreService do
  let(:channel) { create(:channel_app_store) }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: inbox.account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'review-1') }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, contact_inbox: contact_inbox, account: inbox.account) }
  let(:status_update_service) { instance_double(Messages::StatusUpdateService, perform: true) }
  let(:exception_tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }

  before do
    allow(Messages::StatusUpdateService).to receive(:new).and_return(status_update_service)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
  end

  describe '#perform' do
    it 'creates an App Store response for a new reply' do
      message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Thanks')

      allow(channel).to receive(:reply_to_review).and_return('response-1')

      described_class.new(message: message).perform

      expect(channel).to have_received(:reply_to_review).with('review-1', 'Thanks', response_id: nil)
      expect(message.reload.source_id).to eq('response-1')
      expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'delivered')
    end

    it 'updates the existing App Store response when the conversation already has one' do
      create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Old reply',
                       source_id: 'response-1')
      message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Updated reply')

      allow(channel).to receive(:reply_to_review).and_return('response-1')

      described_class.new(message: message).perform

      expect(channel).to have_received(:reply_to_review).with('review-1', 'Updated reply', response_id: 'response-1')
      expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'delivered')
    end

    it 'marks the message as failed when attachments are present' do
      message = create(:message, :with_attachment, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account)

      described_class.new(message: message).perform

      expect(Messages::StatusUpdateService).to have_received(:new).with(
        message,
        'failed',
        'Sending attachments is not supported for App Store reviews.'
      )
      expect(exception_tracker).to have_received(:capture_exception)
    end
  end
end
