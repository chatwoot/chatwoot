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

    # A bot that is still the assignee keeps the conversation out of `unassigned` and out of
    # auto-assignment, so an `open` that leaves it there is a conversation nobody sees.
    it 'hands a bot-owned conversation to the human queue' do
      agent_bot = create(:agent_bot, account: account)
      pending_conversation.update!(ai_assignee: agent_bot, waiting_since: nil)
      allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
      payload = { event: 'message_created', id: pending_message.id }

      described_class.perform(payload, webhook_type, error)

      expect(Conversation.unassigned.open).to include(pending_conversation)
      expect(pending_conversation.reload.waiting_since).to be_present
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Conversation::CONVERSATION_BOT_HANDOFF, anything, hash_including(conversation: pending_conversation))
    end

    # Two messages in a row exhaust their ladders milliseconds apart, and both handlers read the
    # conversation as pending before either one writes.
    it 'hands off once when a second exhausted delivery read the conversation before the first' do
      pending_conversation.update!(ai_assignee: create(:agent_bot, account: account))
      stale_message = Message.find(pending_message.id)
      stale_message.conversation.status
      payload = { event: 'message_created', id: pending_message.id }

      described_class.perform(payload, webhook_type, error)
      allow(Message).to receive(:find_by).with(id: pending_message.id).and_return(stale_message)
      described_class.perform(payload, webhook_type, error)

      expect(Conversations::ActivityMessageJob).to have_been_enqueued.once
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

  context 'when webhook type is agent_bot_observer_webhook' do
    let!(:pending_conversation) { create(:conversation, inbox: inbox, status: :pending, account: account) }
    let!(:pending_message) { create(:message, account: account, inbox: inbox, conversation: pending_conversation) }

    it 'leaves a pending conversation with its responder' do
      payload = { event: 'message_created', id: pending_message.id }

      described_class.perform(payload, :agent_bot_observer_webhook, error)

      expect(pending_conversation.reload.status).to eq('pending')
      expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
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

    # The retries put minutes between the send and this handler, and the channel can report the
    # message delivered or read inside that window. `Messages::StatusUpdateService` only refuses
    # `read` -> `delivered`, so nothing below it stops a stale failure from landing on top of a
    # message the customer already has, which is what puts a resend in front of an agent.
    %i[delivered read].each do |later_status|
      it "leaves a message already #{later_status} alone" do
        message.update!(status: later_status)
        payload = { event: 'message_created', id: message.id }

        described_class.perform(payload, webhook_type, error)

        expect(message.reload.status).to eq(later_status.to_s)
        expect(message.external_error).to be_nil
      end
    end

    it 'still fails a message that never moved past sent' do
      payload = { event: 'message_created', id: message.id }

      described_class.perform(payload, webhook_type, error)

      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to eq(error.message)
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
