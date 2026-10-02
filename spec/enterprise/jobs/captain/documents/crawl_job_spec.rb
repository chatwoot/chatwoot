require 'rails_helper'

RSpec.describe Captain::Documents::CrawlJob, type: :job do
  let(:document) { create(:captain_document, external_link: 'https://example.com/page') }
  let(:assistant_id) { document.assistant_id }
  let(:webhook_url) { Rails.application.routes.url_helpers.enterprise_webhooks_firecrawl_url }

  describe '#perform' do
    context 'when CAPTAIN_FIRECRAWL_API_KEY is configured' do
      let(:firecrawl_spider) { instance_double(WebCrawling::Firecrawl::Spider) }
      let(:account) { document.account }
      let(:token) { Digest::SHA256.hexdigest("-key#{document.assistant_id}#{document.account_id}") }
      let(:submission) do
        WebCrawling::Types::CrawlSubmission.new(provider: :firecrawl, external_id: 'crawl-123', status: 'queued')
      end

      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: 'test-key')
        allow(WebCrawling::Firecrawl::Spider).to receive(:new).and_return(firecrawl_spider)
        allow(firecrawl_spider).to receive(:crawl).and_return(submission)
      end

      context 'with account usage limits' do
        before do
          allow(account).to receive(:usage_limits).and_return({ captain: { documents: { current_available: 20 } } })
        end

        it 'uses FirecrawlService with the correct crawl limit' do
          expect(firecrawl_spider).to receive(:crawl).with(
            url: document.external_link,
            callback_url: "#{webhook_url}?assistant_id=#{assistant_id}&token=#{token}",
            limit: 20,
            request_id: kind_of(String)
          )

          described_class.perform_now(document)
        end
      end

      context 'when crawl limit exceeds maximum' do
        before do
          allow(account).to receive(:usage_limits).and_return({ captain: { documents: { current_available: 1000 } } })
        end

        it 'caps the crawl limit at 500' do
          expect(firecrawl_spider).to receive(:crawl).with(
            url: document.external_link,
            callback_url: "#{webhook_url}?assistant_id=#{assistant_id}&token=#{token}",
            limit: 500,
            request_id: kind_of(String)
          )

          described_class.perform_now(document)
        end
      end

      context 'with no usage limits configured' do
        before do
          allow(account).to receive(:usage_limits).and_return({})
        end

        it 'uses default crawl limit of 10' do
          expect(firecrawl_spider).to receive(:crawl).with(
            url: document.external_link,
            callback_url: "#{webhook_url}?assistant_id=#{assistant_id}&token=#{token}",
            limit: 10,
            request_id: kind_of(String)
          )

          described_class.perform_now(document)
        end
      end
    end

    context 'when Context.dev is selected' do
      let(:context_spider) { instance_double(WebCrawling::ContextDev::Spider) }

      before do
        create(:installation_config, name: WebCrawling::Factory::CONFIG_KEY, value: 'context_dev')
        create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: 'context-key')
        allow(WebCrawling::ContextDev::Spider).to receive(:new).and_return(context_spider)
        allow(document.account).to receive(:usage_limits).and_return({ captain: { documents: { current_available: 25 } } })
      end

      it 'submits the crawl and stores its webhook credentials' do
        job = described_class.new(document)
        callback_url = Rails.application.routes.url_helpers.enterprise_webhooks_context_dev_url(document_id: document.id)
        submission = WebCrawling::Types::CrawlSubmission.new(
          provider: :context_dev,
          external_id: 'batch-123',
          status: 'queued',
          metadata: { 'webhook_secret' => 'whsec_test' }
        )
        expect(context_spider).to receive(:crawl).with(
          url: document.external_link,
          callback_url: callback_url,
          limit: 25,
          request_id: job.job_id
        ).and_return(submission)
        expect(Captain::Tools::ContextDevPollJob).to receive(:schedule).with(
          document_id: document.id,
          batch_id: 'batch-123'
        )

        job.perform_now

        expect(document.reload).to have_attributes(
          web_crawling_provider: 'context_dev',
          web_crawling_external_id: 'batch-123',
          web_crawling_webhook_secret: 'whsec_test'
        )
      end
    end

    context 'when CAPTAIN_FIRECRAWL_API_KEY is not configured' do
      let(:page_links) { ['https://example.com/page1', 'https://example.com/page2'] }
      let(:simple_crawler) { instance_double(Captain::Tools::SimplePageCrawlService) }

      before do
        allow(Captain::Tools::SimplePageCrawlService)
          .to receive(:new)
          .with(document.external_link)
          .and_return(simple_crawler)

        allow(simple_crawler).to receive(:page_links).and_return(page_links)
      end

      it 'enqueues SimplePageCrawlParserJob for each discovered link' do
        page_links.each do |link|
          expect(Captain::Tools::SimplePageCrawlParserJob)
            .to receive(:perform_later)
            .with(
              assistant_id: assistant_id,
              page_link: link
            )
        end

        # Should also crawl the original link
        expect(Captain::Tools::SimplePageCrawlParserJob)
          .to receive(:perform_later)
          .with(
            assistant_id: assistant_id,
            page_link: document.external_link
          )

        described_class.perform_now(document)
      end

      it 'uses SimplePageCrawlService to discover page links' do
        expect(simple_crawler).to receive(:page_links)
        described_class.perform_now(document)
      end
    end

    context 'when document is a PDF' do
      let(:pdf_document) do
        doc = create(:captain_document, external_link: 'https://example.com/document')
        allow(doc).to receive(:pdf_document?).and_return(true)
        allow(doc).to receive(:update!).and_return(true)
        doc
      end

      it 'processes PDF using PdfProcessingService' do
        pdf_service = instance_double(Captain::Llm::PdfProcessingService)
        expect(Captain::Llm::PdfProcessingService).to receive(:new).with(pdf_document).and_return(pdf_service)
        expect(pdf_service).to receive(:process)
        expect(pdf_document).to receive(:update!).with(status: :available)

        described_class.perform_now(pdf_document)
      end

      it 'handles PDF processing errors' do
        allow(Captain::Llm::PdfProcessingService).to receive(:new).and_raise(StandardError, 'Processing failed')

        expect { described_class.perform_now(pdf_document) }.to raise_error(StandardError, 'Processing failed')
      end
    end
  end
end
