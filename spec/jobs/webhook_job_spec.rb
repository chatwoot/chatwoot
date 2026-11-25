require 'rails_helper'

RSpec.describe WebhookJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(url, payload, webhook_type) }

  let(:url) { 'https://test.chatwoot.com' }
  let(:payload) { { name: 'test' } }
  let(:webhook_type) { :account_webhook }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(url, payload, webhook_type)
      .on_queue('medium')
  end

  it 'executes perform with default webhook type' do
    expect(Webhooks::Trigger).to receive(:execute).with(url, payload, webhook_type, secret: nil, delivery_id: nil)
    perform_enqueued_jobs { job }
  end

  context 'with custom webhook type' do
    let(:webhook_type) { :api_inbox_webhook }

    it 'executes perform with inbox webhook type' do
      expect(Webhooks::Trigger).to receive(:execute).with(url, payload, webhook_type, secret: nil, delivery_id: nil)
      perform_enqueued_jobs { job }
    end
  end

  describe 'retry behavior for 404 errors' do
    let!(:account) { create(:account) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, inbox: inbox) }
    let!(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }
    let(:payload) { { event: 'message_created', id: message.id } }
    let(:webhook_type) { :api_inbox_webhook }

    it 'is configured to retry on CustomExceptions::Webhook::RetriableError' do
      retry_handler = described_class.rescue_handlers.find do |handler|
        handler[0] == 'CustomExceptions::Webhook::RetriableError'
      end

      expect(retry_handler).to be_present
    end

    context 'when webhook type is api_inbox_webhook' do
      let(:webhook_type) { :api_inbox_webhook }

      it 'marks message as failed after retries are exhausted' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(
          CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
        )

        perform_enqueued_jobs { job }

        expect(message.reload.status).to eq('failed')
      end
    end

    context 'when webhook type is agent_bot_webhook' do
      let(:webhook_type) { :agent_bot_webhook }

      before { conversation.update!(status: :pending) }

      it 'opens conversation and creates activity message after retries are exhausted' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(
          CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
        )

        perform_enqueued_jobs { job }

        expect(conversation.reload.status).to eq('open')
        activity_message = conversation.messages.where(message_type: :activity).last
        expect(activity_message.content).to eq(I18n.t('conversations.activity.agent_bot.error_moved_to_open'))
      end

      it 'does not change message status' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(
          CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
        )

        expect { perform_enqueued_jobs { job } }.not_to(change { message.reload.status })
      end

      # These drive the REAL Webhooks::Trigger and stub only the HTTP call. Stubbing
      # `Trigger.execute` (as the examples above do) skips `handle_failure` entirely, so it cannot
      # tell escalation-on-attempt-1 from escalation-on-exhaustion, which is the whole point here.
      context 'with the real trigger and a failing transport' do
        let(:payload) { { event: 'message_created', id: message.id } }

        def stub_fetch_failing(times:)
          calls = 0
          allow(SafeFetch).to receive(:fetch) do |*_args|
            calls += 1
            raise SafeFetch::HttpError, '404 Not Found' if calls <= times

            nil
          end
          -> { calls }
        end

        it 'does not escalate while attempts remain, so a later attempt still reaches a pending conversation' do
          calls = stub_fetch_failing(times: 4)

          perform_enqueued_jobs { job }

          expect(calls.call).to eq(5)
          expect(conversation.reload.status).to eq('pending')
          expect(conversation.messages.where(message_type: :activity)).to be_empty
        end

        it 'escalates exactly once when every attempt fails' do
          stub_fetch_failing(times: 5)

          perform_enqueued_jobs { job }

          expect(conversation.reload.status).to eq('open')
          expect(conversation.messages.where(message_type: :activity).count).to eq(1)
        end

        it 'honours keep_pending_on_bot_failure even after the attempts are exhausted' do
          conversation.account.update!(keep_pending_on_bot_failure: true)
          stub_fetch_failing(times: 5)

          perform_enqueued_jobs { job }

          expect(conversation.reload.status).to eq('pending')
          expect(conversation.messages.where(message_type: :activity)).to be_empty
        end
      end

      context 'when conversation is not pending' do
        before { conversation.update!(status: :open) }

        it 'does not create activity message' do
          allow(Webhooks::Trigger).to receive(:execute).and_raise(
            CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
          )

          expect(Conversations::ActivityMessageJob).not_to receive(:perform_later)

          perform_enqueued_jobs { job }
        end
      end
    end

    context 'when webhook type is account_webhook' do
      let(:webhook_type) { :account_webhook }

      it 'does not update message status' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(
          CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
        )

        expect { perform_enqueued_jobs { job } }.not_to(change { message.reload.status })
      end

      it 'does not create activity message' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(
          CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
        )

        expect(Conversations::ActivityMessageJob).not_to receive(:perform_later)

        perform_enqueued_jobs { job }
      end
    end

    context 'when event is not message_created or message_updated' do
      let(:payload) { { event: 'conversation_created', id: conversation.id } }

      it 'does not update any message status' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(
          CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
        )

        expect(Messages::StatusUpdateService).not_to receive(:new)

        perform_enqueued_jobs { job }
      end
    end

    context 'when payload has no id' do
      let(:payload) { { event: 'message_created' } }

      it 'does not attempt to update message status' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(
          CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
        )

        expect(Messages::StatusUpdateService).not_to receive(:new)

        perform_enqueued_jobs { job }
      end
    end

    context 'when message does not exist' do
      let(:payload) { { event: 'message_created', id: -1 } }

      it 'handles gracefully without raising' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(
          CustomExceptions::Webhook::RetriableError.new('Webhook endpoint not found')
        )

        expect { perform_enqueued_jobs { job } }.not_to raise_error
      end
    end
  end
end
