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
end

RSpec.describe WebhookJob, 'delivery retries' do
  include ActiveJob::TestHelper

  let(:url) { 'https://test.chatwoot.com' }
  let(:payload) { { event: 'conversation_updated', id: 42 } }
  let(:secret) { 'test-secret' }
  let(:delivery_id) { 'stable-delivery-id' }
  let(:retryable_error) { Webhooks::Trigger::RetryableError.new(status: 503, message: '503 Service Unavailable') }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  [nil, :account_webhook, :api_inbox_webhook].each do |type|
    context "with #{type || 'default'} webhook type" do
      let(:arguments) { type ? [url, payload, type] : [url, payload] }
      let(:expected_type) { type || :account_webhook }

      it 'preserves signing options and handles failure once after three attempts' do
        allow(Webhooks::Trigger).to receive(:execute).and_raise(retryable_error)
        failed_trigger = instance_double(Webhooks::Trigger)
        allow(Webhooks::Trigger).to receive(:new)
          .with(url, payload, expected_type, secret: secret, delivery_id: delivery_id).and_return(failed_trigger)

        expect(Webhooks::Trigger).to receive(:execute)
          .with(url, payload, expected_type, secret: secret, delivery_id: delivery_id).exactly(3).times
        expect(failed_trigger).to receive(:handle_failure).with(retryable_error).once

        perform_enqueued_jobs do
          described_class.perform_later(*arguments, secret: secret, delivery_id: delivery_id)
        end
      end

      it 'stops retrying when the second attempt succeeds without invoking failure handling' do
        attempts = 0
        allow(Webhooks::Trigger).to receive(:execute) do
          attempts += 1
          raise retryable_error if attempts == 1
        end
        expect(Webhooks::Trigger).not_to receive(:new)

        perform_enqueued_jobs do
          described_class.perform_later(*arguments, secret: secret, delivery_id: delivery_id)
        end

        expect(attempts).to eq(2)
      end
    end
  end

  it 'keeps the same delivery ID and body but signs each retry with a fresh timestamp' do
    requests = []
    times = [Time.utc(2026, 9, 22, 0, 0, 0), Time.utc(2026, 9, 22, 0, 0, 3)]
    allow(GlobalConfig).to receive(:get_value).with('WEBHOOK_TIMEOUT').and_return(5)
    allow(SafeFetch).to receive(:fetch) do |_url, **options|
      requests << options
      raise SafeFetch::HttpError, '503 Service Unavailable' if requests.one?
    end

    times.each do |time|
      travel_to time do
        if requests.empty?
          expect do
            described_class.new.perform(url, payload, :account_webhook, secret: secret, delivery_id: delivery_id)
          end.to raise_error { |error| expect(error.class.name).to eq('Webhooks::Trigger::RetryableError') }
        else
          described_class.new.perform(url, payload, :account_webhook, secret: secret, delivery_id: delivery_id)
        end
      end
    end

    expect(requests.map { |request| request[:body] }.uniq).to eq([payload.to_json])
    expect(requests.map { |request| request[:headers]['X-Chatwoot-Delivery'] }.uniq).to eq([delivery_id])
    expect(requests.map { |request| request[:headers]['X-Chatwoot-Timestamp'] }).to eq(times.map { |time| time.to_i.to_s })
    requests.each do |request|
      timestamp = request[:headers]['X-Chatwoot-Timestamp']
      signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{timestamp}.#{request[:body]}")}"
      expect(request[:headers]['X-Chatwoot-Signature']).to eq(signature)
    end
  end

  it 'marks an API inbox message failed only after the final attempt' do
    message = create(:message, message_type: :outgoing)
    payload = { event: 'message_created', id: message.id }
    attempts = 0
    allow(GlobalConfig).to receive(:get_value).and_call_original
    allow(GlobalConfig).to receive(:get_value).with('WEBHOOK_TIMEOUT').and_return(5)
    allow(SafeFetch).to receive(:fetch) do
      attempts += 1
      expect(message.reload.status).to eq('sent')
      raise SafeFetch::HttpError, '503 Service Unavailable'
    end
    clear_enqueued_jobs

    perform_enqueued_jobs do
      described_class.perform_later(url, payload, :api_inbox_webhook, secret: secret, delivery_id: delivery_id)
    end

    expect(attempts).to eq(3)
    expect(message.reload.status).to eq('failed')
  end
end
