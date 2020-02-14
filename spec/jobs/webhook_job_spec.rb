require 'rails_helper'

RSpec.describe WebhookJob, type: :job do
  subject(:job) { described_class.perform_later(url, payload) }

  let(:url) { 'https://test.com' }
  let(:payload) { { name: 'test' } }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(url, payload)
      .on_queue('webhooks')
  end
end
