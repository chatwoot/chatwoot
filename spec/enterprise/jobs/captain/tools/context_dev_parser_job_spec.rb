require 'rails_helper'

RSpec.describe Captain::Tools::ContextDevParserJob, type: :job do
  let(:source_document) { create(:captain_document, external_link: 'https://example.com/docs') }
  let(:batch_id) { 'batch-123' }
  let(:spider) { instance_double(WebCrawling::ContextDev::Spider) }

  before do
    source_document.update!(
      web_crawling_provider: 'context_dev',
      web_crawling_external_id: batch_id,
      web_crawling_webhook_secret: 'whsec_test'
    )
    allow(WebCrawling::ContextDev::Spider).to receive(:new).and_return(spider)
  end

  it 'persists normalized pages and clears the completed submission' do
    allow(spider).to receive(:fetch_results).with(batch_id: batch_id, cursor: nil).and_return(
      WebCrawling::Types::BatchResults.new(
        pages: [
          WebCrawling::Types::Page.new(
            url: 'https://example.com/docs/',
            title: 'Documentation',
            markdown: '# Documentation',
            status_code: 200
          )
        ],
        has_more: false
      )
    )

    described_class.perform_now(document_id: source_document.id, batch_id: batch_id, event: 'batch.completed')

    expect(source_document.reload).to have_attributes(
      name: 'Documentation',
      content: '# Documentation',
      status: 'available',
      sync_status: 'synced',
      web_crawling_external_id: nil,
      web_crawling_webhook_secret: nil
    )
  end

  it 'continues through paginated results' do
    allow(spider).to receive(:fetch_results).and_return(
      WebCrawling::Types::BatchResults.new(pages: [], has_more: true, next_cursor: 'next-page')
    )

    expect(described_class).to receive(:perform_later).with(
      document_id: source_document.id,
      batch_id: batch_id,
      event: 'batch.completed',
      cursor: 'next-page'
    )

    described_class.perform_now(document_id: source_document.id, batch_id: batch_id, event: 'batch.completed')
  end

  it 'marks the source document failed when the batch does not complete' do
    described_class.perform_now(document_id: source_document.id, batch_id: batch_id, event: 'batch.failed')

    expect(source_document.reload).to have_attributes(
      status: 'available',
      sync_status: 'failed',
      last_sync_error_code: 'fetch_failed',
      web_crawling_external_id: nil,
      web_crawling_webhook_secret: nil
    )
  end

  it 'marks an existing page failed from a normalized result error' do
    allow(spider).to receive(:fetch_results).and_return(
      WebCrawling::Types::BatchResults.new(
        pages: [WebCrawling::Types::Page.new(url: source_document.external_link, error_code: 'not_found')],
        has_more: false
      )
    )

    described_class.perform_now(document_id: source_document.id, batch_id: batch_id, event: 'batch.completed')

    expect(source_document.reload).to have_attributes(sync_status: 'failed', last_sync_error_code: 'not_found')
  end
end
