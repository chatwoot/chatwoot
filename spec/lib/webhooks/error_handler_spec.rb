require 'rails_helper'

describe Webhooks::ErrorHandler do
  include ActiveJob::TestHelper

  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let!(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }
  let(:error) { StandardError.new('webhook failed') }
  let(:agent_bot_error_content) { I18n.t('conversations.activity.agent_bot.error_moved_to_open') }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  context 'when webhook type is agent_bot_webhook' do
    let(:webhook_type) { :agent_bot_webhook }
    let!(:pending_conversation) { create(:conversation, inbox: inbox, status: :pending, account: account) }
    let!(:pending_message) { create(:message, account: account, inbox: inbox, conversation: pending_conversation) }

    it 'reopens conversation and enqueues activity message if pending' do
      payload = { event: 'message_created', id: pending_message.id }

      perform_enqueued_jobs do
        described_class.perform(payload, webhook_type, error)
      end

      expect(pending_conversation.reload.status).to eq('open')

      activity_message = pending_conversation.reload.messages.order(:created_at).last
      expect(activity_message.message_type).to eq('activity')
      expect(activity_message.content).to eq(agent_bot_error_content)
    end

    it 'does not change conversation status or enqueue activity when conversation is not pending' do
      payload = { event: 'message_created', id: message.id }

      described_class.perform(payload, webhook_type, error)

      expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
      expect(conversation.reload.status).to eq('open')
    end

    it 'keeps conversation pending when keep_pending_on_bot_failure setting is enabled' do
      account.update!(keep_pending_on_bot_failure: true)
      payload = { event: 'message_created', id: pending_message.id }

      described_class.perform(payload, webhook_type, error)

      expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
      expect(pending_conversation.reload.status).to eq('pending')
    end

    it 'reopens conversation when keep_pending_on_bot_failure setting is disabled' do
      account.update!(keep_pending_on_bot_failure: false)
      payload = { event: 'message_created', id: pending_message.id }

      perform_enqueued_jobs do
        described_class.perform(payload, webhook_type, error)
      end

      expect(pending_conversation.reload.status).to eq('open')

      activity_message = pending_conversation.reload.messages.order(:created_at).last
      expect(activity_message.message_type).to eq('activity')
      expect(activity_message.content).to eq(agent_bot_error_content)
    end
  end

  context 'when webhook type is api_inbox_webhook' do
    let(:webhook_type) { :api_inbox_webhook }

    it 'updates message status to failed' do
      payload = { event: 'message_created', id: message.id }

      service = instance_double(Messages::StatusUpdateService, perform: nil)
      allow(Messages::StatusUpdateService).to receive(:new)
        .with(message, 'failed', error.message)
        .and_return(service)

      described_class.perform(payload, webhook_type, error)

      expect(service).to have_received(:perform)
    end
  end

  context 'when event is not supported' do
    it 'does not perform any error handling' do
      payload = { event: 'conversation_created', id: message.id }

      described_class.perform(payload, :api_inbox_webhook, error)

      expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
    end
  end
end
