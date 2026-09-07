require 'rails_helper'

RSpec.describe Captain::Tools::ContextDevPollJob, type: :job do
  let(:document) { create(:captain_document, external_link: 'https://example.com/docs') }
  let(:batch_id) { 'batch-123' }
  let(:spider) { instance_double(WebCrawling::ContextDev::Spider) }

  before do
    document.update!(web_crawling_provider: 'context_dev', web_crawling_external_id: batch_id)
    allow(WebCrawling::ContextDev::Spider).to receive(:new).and_return(spider)
  end

  describe '.schedule' do
    it 'schedules checks at one, three, and eight minutes' do
      expect(described_class).to receive(:set).with(wait: 1.minute).ordered.and_call_original
      expect(described_class).to receive(:set).with(wait: 3.minutes).ordered.and_call_original
      expect(described_class).to receive(:set).with(wait: 8.minutes).ordered.and_call_original

      described_class.schedule(document_id: document.id, batch_id: batch_id)
    end
  end

  it 'enqueues result parsing when the batch completed' do
    allow(spider).to receive(:batch_status).with(batch_id: batch_id).and_return('completed')

    expect(Captain::Tools::ContextDevParserJob).to receive(:perform_later).with(
      document_id: document.id,
      batch_id: batch_id,
      event: 'batch.completed'
    )

    described_class.perform_now(document_id: document.id, batch_id: batch_id)
  end

  it 'does nothing while the batch is active' do
    allow(spider).to receive(:batch_status).with(batch_id: batch_id).and_return('running')

    expect(Captain::Tools::ContextDevParserJob).not_to receive(:perform_later)

    described_class.perform_now(document_id: document.id, batch_id: batch_id)
  end

  it 'does not request status after webhook processing clears the batch' do
    document.update!(web_crawling_external_id: nil)

    expect(spider).not_to receive(:batch_status)

    described_class.perform_now(document_id: document.id, batch_id: batch_id)
  end
end
