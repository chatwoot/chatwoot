require 'rails_helper'

RSpec.describe Captain::Documents::CrawlJob, type: :job do
  let(:document) { create(:captain_document, external_link: 'https://example.com/page') }
  let(:assistant_id) { document.assistant_id }
  let(:webhook_url) { Rails.application.routes.url_helpers.enterprise_webhooks_firecrawl_url }

  describe '#perform' do
    context 'when CAPTAIN_FIRECRAWL_API_KEY is configured' do
      let(:firecrawl_service) { instance_double(Captain::Tools::FirecrawlService) }
      let(:account) { document.account }
      let(:token) { Digest::SHA256.hexdigest("-key#{document.assistant_id}#{document.account_id}") }

      before do
        allow(Captain::Tools::FirecrawlService).to receive(:new).and_return(firecrawl_service)
        allow(firecrawl_service).to receive(:perform)

        # Make sure we have the Firecrawl config properly set
        config = InstallationConfig.find_or_create_by(name: 'CAPTAIN_FIRECRAWL_API_KEY') do |config|
          config.value = 'test-key'
        end
        if config.value != 'test-key'
          config.value = 'test-key'
          config.save!
        end

        # Mock simple crawl service to avoid HTTP calls if it somehow gets called
        simple_crawler = instance_double(Captain::Tools::SimplePageCrawlService)
        allow(Captain::Tools::SimplePageCrawlService).to receive(:new).and_return(simple_crawler)
        allow(simple_crawler).to receive(:page_links).and_return([])
      end

      context 'with account usage limits' do
        before do
          allow(account).to receive(:usage_limits).and_return({ captain: { documents: { current_available: 20 } } })
        end

        it 'uses FirecrawlService with the correct crawl limit' do
          expect(firecrawl_service).to receive(:perform).with(
            document.external_link,
            "#{webhook_url}?assistant_id=#{assistant_id}&token=#{token}",
            20
          )

          described_class.perform_now(document)
        end
      end

      context 'when crawl limit exceeds maximum' do
        before do
          allow(account).to receive(:usage_limits).and_return({ captain: { documents: { current_available: 1000 } } })
        end

        it 'caps the crawl limit at 500' do
          expect(firecrawl_service).to receive(:perform).with(
            document.external_link,
            "#{webhook_url}?assistant_id=#{assistant_id}&token=#{token}",
            500
          )

          described_class.perform_now(document)
        end
      end

      context 'with no usage limits configured' do
        before do
          allow(account).to receive(:usage_limits).and_return({})
        end

        it 'uses default crawl limit of 10' do
          expect(firecrawl_service).to receive(:perform).with(
            document.external_link,
            "#{webhook_url}?assistant_id=#{assistant_id}&token=#{token}",
            10
          )

          described_class.perform_now(document)
        end
      end
    end

    context 'when CAPTAIN_FIRECRAWL_API_KEY is not configured' do
      let(:page_links) { ['https://example.com/page1', 'https://example.com/page2'] }
      let(:simple_crawler) { instance_double(Captain::Tools::SimplePageCrawlService) }

      before do
        allow(Captain::Tools::SimplePageCrawlService)
          .to receive(:new)
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

      context 'when document is a PDF' do
        let(:pdf_document) { create(:captain_document, external_link: 'https://example.com/document.pdf') }

        it 'delegates to PDFExtractionJob' do
          expect(Captain::Documents::PdfExtractionJob)
            .to receive(:perform_later)
            .with(pdf_document)

          described_class.perform_now(pdf_document)
        end
      end
    end

    describe '#pdf_document?' do
      let(:job) { described_class.new }

      it 'detects PDF by source type' do
        pdf_doc = build(:captain_document, source_type: 'pdf_upload')
        expect(job.send(:pdf_document?, pdf_doc)).to be true
      end

      it 'returns false for non-PDF documents' do
        web_doc = build(:captain_document, external_link: 'https://example.com/page.html')
        expect(job.send(:pdf_document?, web_doc)).to be false
      end
    end
  end
end
