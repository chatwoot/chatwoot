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
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: 'test-key')
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

      context 'when document is a PDF' do
        let(:pdf_document) { create(:captain_document, external_link: 'https://example.com/document.pdf') }
        let(:pdf_service) { instance_double(Captain::Tools::PdfExtractionService) }
        let(:pdf_content) do
          [
            { content: 'PDF page 1 content', page_number: 1, chunk_index: 1, total_chunks: 1 },
            { content: 'PDF page 2 content', page_number: 2, chunk_index: 1, total_chunks: 1 }
          ]
        end

        before do
          allow(Captain::Tools::PdfExtractionService)
            .to receive(:new)
            .with(pdf_document.external_link)
            .and_return(pdf_service)
        end

        it 'processes PDF using PdfExtractionService when extraction succeeds' do
          allow(pdf_service).to receive(:perform).and_return({
                                                               success: true,
                                                               content: pdf_content
                                                             })
          expect(pdf_service).to receive(:perform)
          described_class.perform_now(pdf_document)
        end

        it 'enqueues PdfExtractionParserJob for each content chunk when extraction succeeds' do
          allow(pdf_service).to receive(:perform).and_return({
                                                               success: true,
                                                               content: pdf_content
                                                             })
          pdf_content.each do |chunk|
            expect(Captain::Tools::PdfExtractionParserJob)
              .to receive(:perform_later)
              .with(
                assistant_id: pdf_document.assistant_id,
                pdf_content: chunk,
                document_id: pdf_document.id
              )
          end

          described_class.perform_now(pdf_document)
        end

        it 'updates document status to processing when extraction succeeds' do
          allow(pdf_service).to receive(:perform).and_return({
                                                               success: true,
                                                               content: pdf_content
                                                             })
          allow(Captain::Tools::PdfExtractionParserJob).to receive(:perform_later)

          expect(pdf_document).to receive(:update).with(status: 'processing').twice
          described_class.perform_now(pdf_document)
        end

        it 'updates document status to failed with error message when extraction fails' do
          allow(pdf_service).to receive(:perform).and_return({
                                                               success: false,
                                                               errors: ['Invalid PDF format']
                                                             })
          expect(pdf_document).to receive(:update).with(status: 'processing').once
          expect(pdf_document).to receive(:update).with(
            status: 'failed',
            error_message: 'Invalid PDF format'
          ).once

          described_class.perform_now(pdf_document)
        end

        it 'logs the error when extraction fails' do
          allow(pdf_service).to receive(:perform).and_return({
                                                               success: false,
                                                               errors: ['Invalid PDF format']
                                                             })
          expect(Rails.logger).to receive(:error).with(/PDF extraction failed/)
          described_class.perform_now(pdf_document)
        end

        it 'handles exceptions gracefully during PDF extraction' do
          allow(pdf_service).to receive(:perform).and_raise(StandardError, 'Network error')
          expect(pdf_document).to receive(:update).with(status: 'processing').once
          expect(pdf_document).to receive(:update).with(
            status: 'failed',
            error_message: 'Network error'
          ).once

          described_class.perform_now(pdf_document)
        end

        it 'logs exceptions during PDF extraction' do
          allow(pdf_service).to receive(:perform).and_raise(StandardError, 'Network error')
          expect(Rails.logger).to receive(:error).with(/PDF extraction failed/)
          described_class.perform_now(pdf_document)
        end
      end
    end

    describe '#pdf_document?' do
      let(:job) { described_class.new }

      it 'detects PDF by file extension' do
        pdf_doc = build(:captain_document, external_link: 'https://example.com/file.pdf')
        expect(job.send(:pdf_document?, pdf_doc)).to be true
      end

      it 'detects PDF by content type' do
        pdf_doc = build(:captain_document, content_type: 'application/pdf')
        expect(job.send(:pdf_document?, pdf_doc)).to be true
      end

      it 'detects PDF by source type' do
        pdf_doc = build(:captain_document, source_type: 'pdf_upload')
        expect(job.send(:pdf_document?, pdf_doc)).to be true
      end

      it 'returns false for non-PDF documents' do
        web_doc = build(:captain_document, external_link: 'https://example.com/page.html')
        expect(job.send(:pdf_document?, web_doc)).to be false
      end

      it 'is case insensitive for file extensions' do
        pdf_doc = build(:captain_document, external_link: 'https://example.com/file.PDF')
        expect(job.send(:pdf_document?, pdf_doc)).to be true
      end
    end
  end
end
