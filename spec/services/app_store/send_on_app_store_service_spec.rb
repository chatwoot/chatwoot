# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppStore::SendOnAppStoreService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_app_store, account: account) }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: inbox.account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'review-1') }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, contact_inbox: contact_inbox, account: inbox.account) }
  let(:status_update_service) { instance_double(Messages::StatusUpdateService, perform: true) }
  let(:exception_tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }

  before do
    account.enable_features!(:channel_app_store)
    allow(Messages::StatusUpdateService).to receive(:new).and_return(status_update_service)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
  end

  describe '#perform' do
    it 'creates an App Store response for a new reply' do
      message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Thanks')

      allow(channel).to receive(:reply_to_review).and_return('response-1')

      described_class.new(message: message).perform

      expect(channel).to have_received(:reply_to_review).with('review-1', 'Thanks')
      expect(message.reload.source_id).to eq('response-1')
      expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'delivered')
    end

    it 'updates the existing App Store response when the conversation already has one' do
      existing_response = create(
        :message,
        message_type: :outgoing,
        inbox: inbox,
        conversation: conversation,
        account: inbox.account,
        content: 'Old reply',
        source_id: 'response-1',
        content_attributes: {
          external_echo: true,
          app_store: {
            response_id: 'response-1',
            response_state: 'PUBLISHED'
          }
        }
      )
      message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Updated reply')

      allow(channel).to receive(:reply_to_review).and_return('response-1')

      expect { described_class.new(message: message).perform }
        .to change { conversation.messages.reload.count }.by(-1)

      expect(channel).to have_received(:reply_to_review).with('review-1', 'Updated reply')
      expect { message.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(existing_response.reload.content).to eq('Updated reply')
      expect(existing_response.content_attributes['external_echo']).to be true
      expect(existing_response.content_attributes['app_store']).to include(
        'response_id' => 'response-1',
        'response_state' => 'PUBLISHED'
      )
      expect(Messages::StatusUpdateService).to have_received(:new).with(existing_response, 'delivered')
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

    it 'marks the message as failed when the message is not plain outgoing text' do
      message = create(
        :message,
        message_type: :outgoing,
        content_type: :input_csat,
        inbox: inbox,
        conversation: conversation,
        account: inbox.account,
        content: 'Please rate this conversation'
      )

      allow(channel).to receive(:reply_to_review)

      described_class.new(message: message).perform

      expect(channel).not_to have_received(:reply_to_review)
      expect(Messages::StatusUpdateService).to have_received(:new).with(
        message,
        'failed',
        'Only outgoing text messages are supported for App Store reviews.'
      )
      expect(exception_tracker).to have_received(:capture_exception)
    end

    it 'marks the message as failed when the feature is disabled' do
      account.disable_features!(:channel_app_store)
      message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Thanks')

      described_class.new(message: message).perform

      expect(Messages::StatusUpdateService).to have_received(:new).with(
        message,
        'failed',
        'App Store Reviews channel is not enabled for this account.'
      )
      expect(exception_tracker).to have_received(:capture_exception)
    end
  end
end
