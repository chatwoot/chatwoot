require 'rails_helper'

describe Webhooks::Trigger do
  include ActiveJob::TestHelper

  subject(:trigger) { described_class }

  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, inbox: inbox) }
  let!(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }

  let(:webhook_type) { :api_inbox_webhook }
  let!(:url) { 'https://test.com' }
  let(:agent_bot_error_content) { I18n.t('conversations.activity.agent_bot.error_moved_to_open') }
  let(:default_timeout) { 5 }
  let(:webhook_timeout) { default_timeout }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(GlobalConfig).to receive(:get_value).and_call_original
    allow(GlobalConfig).to receive(:get_value).with('WEBHOOK_TIMEOUT').and_return(webhook_timeout)
    allow(GlobalConfig).to receive(:get_value).with('DEPLOYMENT_ENV').and_return(nil)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#execute' do
    it 'triggers webhook' do
      payload = { hello: :hello }

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: webhook_timeout
        ).once
      trigger.execute(url, payload, webhook_type)
    end

    it 'updates message status if webhook fails for message-created event' do
      payload = { event: 'message_created', conversation: { id: conversation.id }, id: message.id }

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: webhook_timeout
        ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once

      expect { trigger.execute(url, payload, webhook_type) }.to change { message.reload.status }.from('sent').to('failed')
    end

    it 'updates message status if webhook fails for message-updated event' do
      payload = { event: 'message_updated', conversation: { id: conversation.id }, id: message.id }

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: webhook_timeout
        ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once
      expect { trigger.execute(url, payload, webhook_type) }.to change { message.reload.status }.from('sent').to('failed')
    end

    context 'when webhook type is agent bot' do
      let(:webhook_type) { :agent_bot_webhook }
      let!(:pending_conversation) { create(:conversation, inbox: inbox, status: :pending, account: account) }
      let!(:pending_message) { create(:message, account: account, inbox: inbox, conversation: pending_conversation) }

      it 'reopens conversation and enqueues activity message if pending' do
        payload = { event: 'message_created', id: pending_message.id }

        expect(RestClient::Request).to receive(:execute)
          .with(
            method: :post,
            url: url,
            payload: payload.to_json,
            headers: { content_type: :json, accept: :json },
            timeout: webhook_timeout
          ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once

        expect do
          perform_enqueued_jobs do
            trigger.execute(url, payload, webhook_type)
          end
        end.not_to(change { pending_message.reload.status })

        expect(pending_conversation.reload.status).to eq('open')

        activity_message = pending_conversation.reload.messages.order(:created_at).last
        expect(activity_message.message_type).to eq('activity')
        expect(activity_message.content).to eq(agent_bot_error_content)
      end

      it 'does not change message status or enqueue activity when conversation is not pending' do
        payload = { event: 'message_created', conversation: { id: conversation.id }, id: message.id }

        expect(RestClient::Request).to receive(:execute)
          .with(
            method: :post,
            url: url,
            payload: payload.to_json,
            headers: { content_type: :json, accept: :json },
            timeout: webhook_timeout
          ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once

        expect do
          trigger.execute(url, payload, webhook_type)
        end.not_to(change { message.reload.status })

        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
        expect(conversation.reload.status).to eq('open')
      end

      it 'keeps conversation pending when keep_pending_on_bot_failure setting is enabled' do
        account.update(keep_pending_on_bot_failure: true)
        payload = { event: 'message_created', id: pending_message.id }

        expect(RestClient::Request).to receive(:execute)
          .with(
            method: :post,
            url: url,
            payload: payload.to_json,
            headers: { content_type: :json, accept: :json },
            timeout: webhook_timeout
          ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once

        trigger.execute(url, payload, webhook_type)

        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
        expect(pending_conversation.reload.status).to eq('pending')
      end

      it 'reopens conversation when keep_pending_on_bot_failure setting is disabled' do
        account.update(keep_pending_on_bot_failure: false)
        payload = { event: 'message_created', id: pending_message.id }

        expect(RestClient::Request).to receive(:execute)
          .with(
            method: :post,
            url: url,
            payload: payload.to_json,
            headers: { content_type: :json, accept: :json },
            timeout: webhook_timeout
          ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once
        expect do
          perform_enqueued_jobs do
            trigger.execute(url, payload, webhook_type)
          end
        end.not_to(change { pending_message.reload.status })

        expect(pending_conversation.reload.status).to eq('open')

        activity_message = pending_conversation.reload.messages.order(:created_at).last
        expect(activity_message.message_type).to eq('activity')
        expect(activity_message.content).to eq(agent_bot_error_content)
      end
    end
  end

  it 'does not update message status if webhook fails for other events' do
    payload = { event: 'conversation_created', conversation: { id: conversation.id }, id: message.id }

    expect(RestClient::Request).to receive(:execute)
      .with(
        method: :post,
        url: url,
        payload: payload.to_json,
        headers: { content_type: :json, accept: :json },
        timeout: webhook_timeout
      ).and_raise(RestClient::ExceptionWithResponse.new('error', 500)).once

    expect { trigger.execute(url, payload, webhook_type) }.not_to(change { message.reload.status })
  end

  context 'when webhook timeout configuration is blank' do
    let(:webhook_timeout) { nil }

    it 'falls back to default timeout' do
      payload = { hello: :hello }

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: default_timeout
        ).once

      trigger.execute(url, payload, webhook_type)
    end
  end

  context 'when webhook timeout configuration is invalid' do
    let(:webhook_timeout) { -1 }

    it 'falls back to default timeout' do
      payload = { hello: :hello }

      expect(RestClient::Request).to receive(:execute)
        .with(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: default_timeout
        ).once

      trigger.execute(url, payload, webhook_type)
    end
  end
end
