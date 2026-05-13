require 'rails_helper'

RSpec.describe AgentBots::WebhookJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(url, payload, webhook_type) }

  let(:url) { 'https://test.com' }
  let(:payload) { { name: 'test' } }
  let(:webhook_type) { :agent_bot_webhook }
  let(:retryable_error) { Webhooks::Trigger::RetryableError.new(status: 500, message: '500 Internal Server Error') }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(url, payload, webhook_type)
      .on_queue('high')
  end

  it 'executes perform' do
    expect(Webhooks::Trigger).to receive(:execute).with(url, payload, webhook_type, secret: nil, delivery_id: nil)
    perform_enqueued_jobs { job }
  end

  context 'with additional headers' do
    subject(:job) do
      described_class.perform_later(
        url, payload, webhook_type,
        secret: 'secret',
        delivery_id: 'delivery-id',
        additional_headers: { 'Authorization' => 'Bearer bot-token' }
      )
    end

    it 'serializes keyword arguments and passes additional headers to the trigger' do
      expect(Webhooks::Trigger).to receive(:execute).with(
        url, payload, webhook_type,
        secret: 'secret',
        delivery_id: 'delivery-id',
        additional_headers: { 'Authorization' => 'Bearer bot-token' }
      )
      perform_enqueued_jobs { job }
    end

    it 'keeps additional headers available when retry handling is exhausted' do
      allow(Webhooks::Trigger).to receive(:execute).and_raise(retryable_error)
      trigger_instance = instance_double(Webhooks::Trigger, handle_failure: true)
      allow(Webhooks::Trigger).to receive(:new).and_return(trigger_instance)
      allow(Rails.logger).to receive(:warn)

      perform_enqueued_jobs { job }

      expect(Webhooks::Trigger).to have_received(:new).with(
        url, payload, webhook_type,
        secret: 'secret',
        delivery_id: 'delivery-id',
        additional_headers: { 'Authorization' => 'Bearer bot-token' }
      )
      expect(trigger_instance).to have_received(:handle_failure).with(instance_of(Webhooks::Trigger::RetryableError))
    end
  end

  it 'configures retry handlers for 429 and 500 errors' do
    handlers = described_class.rescue_handlers.map(&:first)

    expect(handlers).to include('Webhooks::Trigger::RetryableError')
  end

  it 'retries 3 times and handles failure after retries are exhausted' do
    allow(Webhooks::Trigger).to receive(:execute).and_raise(retryable_error)
    trigger_instance = instance_double(Webhooks::Trigger, handle_failure: true)
    allow(Webhooks::Trigger).to receive(:new).and_return(trigger_instance)
    allow(Rails.logger).to receive(:warn)

    expect(Webhooks::Trigger).to receive(:execute).exactly(3).times
    expect(trigger_instance).to receive(:handle_failure).with(instance_of(Webhooks::Trigger::RetryableError)).once
    expect(Rails.logger).to receive(:warn).with(/AgentBots::WebhookJob/).exactly(3).times

    perform_enqueued_jobs { job }
  end
end
