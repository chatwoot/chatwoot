require 'rails_helper'

RSpec.describe AgentBots::WebhookJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(url, payload) }

  let(:url) { 'https://test.com' }
  let(:payload) { { name: 'test' } }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(url, payload)
      .on_queue('bots')
  end

  it 'executes perform' do
    expect(Webhooks::Trigger).to receive(:execute).with(url, payload)
    perform_enqueued_jobs { job }
  end
end
