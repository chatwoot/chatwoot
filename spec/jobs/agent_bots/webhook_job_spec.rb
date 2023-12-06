require 'rails_helper'

RSpec.describe AgentBots::WebhookJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(url, payload, webhook_type) }

  let(:url) { 'https://test.com' }
  let(:payload) { { name: 'test' } }
  let(:webhook_type) { :agent_bot_webhook }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(url, payload, webhook_type)
      .on_queue('high')
  end

  it 'executes perform' do
    expect(Webhooks::Trigger).to receive(:execute).with(url, payload, webhook_type)
    perform_enqueued_jobs { job }
  end
end
