require 'rails_helper'

describe Webhooks::Trigger do
  include ActiveJob::TestHelper

  subject(:trigger) { described_class }

  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, inbox: inbox) }
  let!(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }

  let(:webhook_type) { :api_inbox_webhook }
  let(:url) { 'https://test.com' }
  let(:payload) { { hello: :hello } }
  let(:fetch_result) { instance_double(SafeFetch::Result) }
  let(:agent_bot_error_content) { I18n.t('conversations.activity.agent_bot.error_moved_to_open') }
  let(:default_timeout) { 5 }
  let(:webhook_timeout) { default_timeout }
  let(:base_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

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
      expect(SafeFetch).to receive(:fetch).with(
        url,
        method: :post,
        body: payload.to_json,
        headers: base_headers,
        open_timeout: webhook_timeout,
        read_timeout: webhook_timeout,
        validate_content_type: false
      ).and_yield(fetch_result)

      trigger.execute(url, payload, webhook_type)
    end

    it 'raises RetriableError when webhook fails' do
      payload = { event: 'message_created', conversation: { id: conversation.id }, id: message.id }

      expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('500 Internal Server Error'))

      expect { trigger.execute(url, payload, webhook_type) }.to raise_error(CustomExceptions::Webhook::RetriableError)
    end

    it 'does not call ErrorHandler directly (deferred to job discard)' do
      payload = { event: 'message_created', conversation: { id: conversation.id }, id: message.id }

      expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('500 Internal Server Error'))

      expect(Webhooks::ErrorHandler).not_to receive(:perform)
      expect { trigger.execute(url, payload, webhook_type) }.to raise_error(CustomExceptions::Webhook::RetriableError)
    end

    it 'treats blocked private webhook URLs as failures without marking the message yet' do
      payload = { event: 'message_created', conversation: { id: conversation.id }, id: message.id }

      expect do
        expect { trigger.execute('http://127.0.0.1/webhook', payload, webhook_type) }
          .to raise_error(CustomExceptions::Webhook::RetriableError)
      end.not_to(change { message.reload.status })
    end

    context 'when webhook type is agent bot' do
      let(:webhook_type) { :agent_bot_webhook }
      let!(:pending_conversation) { create(:conversation, inbox: inbox, status: :pending, account: account) }
      let!(:pending_message) { create(:message, account: account, inbox: inbox, conversation: pending_conversation) }

      it 'raises 500 errors for retry and does not reopen conversation immediately' do
        payload = { event: 'message_created', id: pending_message.id }

        expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('500 Internal Server Error'))

        expect { trigger.execute(url, payload, webhook_type) }
          .to(raise_error do |error|
            expect(error.class.name).to eq('Webhooks::Trigger::RetryableError')
            expect(error.status).to eq(500)
          end)
        expect(pending_conversation.reload.status).to eq('pending')
        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
      end

      it 'raises 429 errors for retry and does not reopen conversation immediately' do
        payload = { event: 'message_created', id: pending_message.id }

        expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('429 Too Many Requests'))

        expect { trigger.execute(url, payload, webhook_type) }
          .to(raise_error do |error|
            expect(error.class.name).to eq('Webhooks::Trigger::RetryableError')
            expect(error.status).to eq(429)
          end)
        expect(pending_conversation.reload.status).to eq('pending')
        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
      end

      it 'leaves a pending conversation alone so the retries can still land' do
        payload = { event: 'message_created', id: pending_message.id }

        expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('404 Not Found'))

        expect { trigger.execute(url, payload, webhook_type) }.to raise_error(CustomExceptions::Webhook::RetriableError)

        # The bot only answers a `pending` conversation. Escalating here would make every redelivery
        # arrive at a conversation the bot will not answer, so the retries could never recover the
        # turn. WebhookJob escalates once, after the attempts are exhausted (see spec/jobs).
        expect(pending_conversation.reload.status).to eq('pending')
        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
      end

      # A 500 or 429 that outlasts AgentBots::WebhookJob's retries ends here, not in ErrorHandler,
      # and it has to land the conversation in the same human queue.
      it 'hands a bot-owned conversation to the human queue once the retries are gone' do
        agent_bot = create(:agent_bot, account: account)
        pending_conversation.update!(ai_assignee: agent_bot, waiting_since: nil)
        allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
        payload = { event: 'message_created', id: pending_message.id }

        perform_enqueued_jobs do
          trigger.new(url, payload, webhook_type).handle_failure(StandardError.new('bot down'))
        end

        expect(Conversation.unassigned.open).to include(pending_conversation)
        expect(pending_conversation.reload.waiting_since).to be_present
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Conversation::CONVERSATION_BOT_HANDOFF, anything, hash_including(conversation: pending_conversation))
        expect(pending_conversation.messages.activity.last.content).to eq(agent_bot_error_content)
      end

      it 'hands off once when a second exhausted delivery read the conversation before the first' do
        pending_conversation.update!(ai_assignee: create(:agent_bot, account: account))
        stale_message = Message.find(pending_message.id)
        stale_message.conversation.status
        payload = { event: 'message_created', id: pending_message.id }

        trigger.new(url, payload, webhook_type).handle_failure(StandardError.new('bot down'))
        allow(Message).to receive(:find_by).with(id: pending_message.id).and_return(stale_message)
        trigger.new(url, payload, webhook_type).handle_failure(StandardError.new('bot down'))

        expect(Conversations::ActivityMessageJob).to have_been_enqueued.once
      end

      it 'keeps a bot-owned conversation pending when the account asks for it' do
        agent_bot = create(:agent_bot, account: account)
        pending_conversation.update!(ai_assignee: agent_bot)
        pending_conversation.account.update!(keep_pending_on_bot_failure: true)
        payload = { event: 'message_created', id: pending_message.id }

        trigger.new(url, payload, webhook_type).handle_failure(StandardError.new('bot down'))

        expect(pending_conversation.reload.status).to eq('pending')
        expect(pending_conversation.ai_assignee).to eq(agent_bot)
        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
      end

      it 'does not change message status or enqueue activity when conversation is not pending' do
        payload = { event: 'message_created', conversation: { id: conversation.id }, id: message.id }

        expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('404 Not Found'))

        expect do
          expect { trigger.execute(url, payload, webhook_type) }
            .to raise_error(CustomExceptions::Webhook::RetriableError)
        end.not_to(change { message.reload.status })

        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
        expect(conversation.reload.status).to eq('open')
      end
    end

    context 'when webhook type is agent bot observer' do
      let(:webhook_type) { :agent_bot_observer_webhook }
      let!(:pending_conversation) { create(:conversation, inbox: inbox, status: :pending, account: account) }
      let!(:pending_message) { create(:message, account: account, inbox: inbox, conversation: pending_conversation) }

      it 'retries a 500 the way the responder does' do
        payload = { event: 'message_created', id: pending_message.id }

        expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('500 Internal Server Error'))

        expect { trigger.execute(url, payload, webhook_type) }
          .to(raise_error do |error|
            expect(error.class.name).to eq('Webhooks::Trigger::RetryableError')
            expect(error.status).to eq(500)
          end)
      end

      it 'never hands a pending conversation to a human when its retries are gone' do
        payload = { event: 'message_created', id: pending_message.id }

        trigger.new(url, payload, webhook_type).handle_failure(StandardError.new('observer down'))

        expect(pending_conversation.reload.status).to eq('pending')
        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
      end
    end

    it 'raises RetriableError for non-agent webhooks on 500 without marking the message failed' do
      payload = { event: 'message_created', conversation: { id: conversation.id }, id: message.id }

      expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('500 Internal Server Error'))

      expect { trigger.execute(url, payload, webhook_type) }.to raise_error(CustomExceptions::Webhook::RetriableError)
      # Still 'sent': four attempts remain, and one of them may deliver. Marking it failed here is
      # what let an agent resend a message the retry had already delivered.
      expect(message.reload.status).to eq('sent')
    end
  end

  describe 'request headers' do
    let(:payload) { { event: 'message_created' } }
    let(:body) { payload.to_json }

    context 'without secret or delivery_id' do
      it 'sends only content-type and accept headers' do
        expect(SafeFetch).to receive(:fetch).with(
          url,
          method: :post,
          body: body,
          headers: base_headers,
          open_timeout: webhook_timeout,
          read_timeout: webhook_timeout,
          validate_content_type: false
        ).and_yield(fetch_result)

        trigger.execute(url, payload, webhook_type)
      end
    end

    context 'with delivery_id' do
      it 'adds X-Chatwoot-Delivery header' do
        expect(SafeFetch).to receive(:fetch) do |received_url, **options, &block|
          expect(received_url).to eq(url)
          expect(options[:headers]['X-Chatwoot-Delivery']).to eq('test-uuid')
          expect(options[:headers]).not_to have_key('X-Chatwoot-Signature')
          expect(options[:headers]).not_to have_key('X-Chatwoot-Timestamp')
          block.call(fetch_result)
        end

        trigger.execute(url, payload, webhook_type, delivery_id: 'test-uuid')
      end
    end

    context 'with secret' do
      let(:secret) { 'test-secret' }

      it 'adds X-Chatwoot-Timestamp header' do
        expect(SafeFetch).to receive(:fetch) do |_received_url, **options, &block|
          expect(options[:headers]['X-Chatwoot-Timestamp']).to match(/\A\d+\z/)
          block.call(fetch_result)
        end

        trigger.execute(url, payload, webhook_type, secret: secret)
      end

      it 'adds X-Chatwoot-Signature header with correct HMAC' do
        expect(SafeFetch).to receive(:fetch) do |_received_url, **options, &block|
          ts = options[:headers]['X-Chatwoot-Timestamp']
          expected_sig = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{ts}.#{body}")}"
          expect(options[:headers]['X-Chatwoot-Signature']).to eq(expected_sig)
          block.call(fetch_result)
        end

        trigger.execute(url, payload, webhook_type, secret: secret)
      end

      it 'signs timestamp.body not just body' do
        expect(SafeFetch).to receive(:fetch) do |_received_url, **options, &block|
          wrong_sig = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, body)}"
          expect(options[:headers]['X-Chatwoot-Signature']).not_to eq(wrong_sig)
          block.call(fetch_result)
        end

        trigger.execute(url, payload, webhook_type, secret: secret)
      end
    end

    context 'with both secret and delivery_id' do
      it 'includes all three security headers' do
        expect(SafeFetch).to receive(:fetch) do |_received_url, **options, &block|
          expect(options[:headers]['X-Chatwoot-Delivery']).to eq('abc-123')
          expect(options[:headers]['X-Chatwoot-Timestamp']).to be_present
          expect(options[:headers]['X-Chatwoot-Signature']).to start_with('sha256=')
          block.call(fetch_result)
        end

        trigger.execute(url, payload, webhook_type, secret: 'mysecret', delivery_id: 'abc-123')
      end
    end
  end

  it 'does not update message status if webhook fails for other events' do
    payload = { event: 'conversation_created', conversation: { id: conversation.id }, id: message.id }

    expect(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('500 Internal Server Error'))

    expect do
      trigger.execute(url, payload, webhook_type)
    rescue CustomExceptions::Webhook::RetriableError
      nil
    end.not_to(change { message.reload.status })
  end

  context 'when webhook timeout configuration is blank' do
    let(:webhook_timeout) { nil }

    it 'falls back to default timeout' do
      expect(SafeFetch).to receive(:fetch).with(
        url,
        method: :post,
        body: payload.to_json,
        headers: base_headers,
        open_timeout: default_timeout,
        read_timeout: default_timeout,
        validate_content_type: false
      ).and_yield(fetch_result)

      trigger.execute(url, payload, webhook_type)
    end
  end

  context 'when webhook timeout configuration is invalid' do
    let(:webhook_timeout) { -1 }

    it 'falls back to default timeout' do
      expect(SafeFetch).to receive(:fetch).with(
        url,
        method: :post,
        body: payload.to_json,
        headers: base_headers,
        open_timeout: default_timeout,
        read_timeout: default_timeout,
        validate_content_type: false
      ).and_yield(fetch_result)

      trigger.execute(url, payload, webhook_type)
    end
  end
end
