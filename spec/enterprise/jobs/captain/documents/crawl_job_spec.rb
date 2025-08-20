require 'rails_helper'

RSpec.describe Captain::Documents::CrawlJob, type: :job do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:url_document) { create(:captain_document, assistant: assistant, account: account, external_link: 'https://example.com') }
  let(:pdf_document) do
    doc = create(:captain_document, assistant: assistant, account: account)
    doc.pdf_file.attach(
      io: File.open(Rails.root.join('spec/fixtures/files/sample.pdf')),
      filename: 'sample.pdf',
      content_type: 'application/pdf'
    )
    doc
  end

  describe '#perform' do
    context 'when document has external link' do
      it 'performs simple crawling when no firecrawl API key' do
        allow(InstallationConfig).to receive(:find_by).and_return(nil)
        job = described_class.new
        expect(job).to receive(:perform_simple_crawl).with(url_document)
        job.perform(url_document)
      end

      it 'does not perform PDF processing' do
        allow(InstallationConfig).to receive(:find_by).and_return(nil)
        # Mock the HTTP request made by SimplePageCrawlService
        stub_request(:get, 'https://example.com/').to_return(status: 200, body: '<html></html>', headers: {})

        simple_crawl_service = instance_double(Captain::Tools::SimplePageCrawlService)
        allow(Captain::Tools::SimplePageCrawlService).to receive(:new).and_return(simple_crawl_service)
        allow(simple_crawl_service).to receive(:page_links).and_return([])

        job = described_class.new
        expect(job).not_to receive(:perform_pdf_processing)
        job.perform(url_document)
      end
    end

    context 'when document has PDF file' do
      it 'performs PDF processing' do
        job = described_class.new
        expect(job).to receive(:perform_pdf_processing).with(pdf_document)
        job.perform(pdf_document)
      end

      it 'does not perform web crawling' do
        job = described_class.new
        allow(job).to receive(:perform_pdf_processing)
        expect(job).not_to receive(:perform_simple_crawl)
        expect(job).not_to receive(:perform_firecrawl_crawl)
        job.perform(pdf_document)
      end

      it 'calls PDF processing service' do
        pdf_processing_service = instance_double(Captain::Llm::PdfProcessingService)
        expect(Captain::Llm::PdfProcessingService).to receive(:new).with(pdf_document).and_return(pdf_processing_service)
        expect(pdf_processing_service).to receive(:process)

        described_class.perform_now(pdf_document)
      end

      it 'marks document as available after processing' do
        pdf_processing_service = instance_double(Captain::Llm::PdfProcessingService)
        allow(Captain::Llm::PdfProcessingService).to receive(:new).with(pdf_document).and_return(pdf_processing_service)
        allow(pdf_processing_service).to receive(:process)

        expect { described_class.perform_now(pdf_document) }
          .to change { pdf_document.reload.status }.to('available')
      end

      it 'logs successful PDF processing' do
        pdf_processing_service = instance_double(Captain::Llm::PdfProcessingService)
        allow(Captain::Llm::PdfProcessingService).to receive(:new).with(pdf_document).and_return(pdf_processing_service)
        allow(pdf_processing_service).to receive(:process)
        allow(Rails.logger).to receive(:info)

        described_class.perform_now(pdf_document)

        expect(Rails.logger).to have_received(:info).with(I18n.t('captain.documents.pdf_processing_success', document_id: pdf_document.id))
      end

      context 'when PDF processing fails' do
        it 'logs error and re-raises' do
          pdf_processing_service = instance_double(Captain::Llm::PdfProcessingService)
          allow(Captain::Llm::PdfProcessingService).to receive(:new).with(pdf_document).and_return(pdf_processing_service)
          allow(pdf_processing_service).to receive(:process).and_raise(StandardError, 'Processing failed')

          allow(Rails.logger).to receive(:error)

          expect { described_class.perform_now(pdf_document) }
            .to raise_error(StandardError, 'Processing failed')

          expect(Rails.logger).to have_received(:error).with(I18n.t('captain.documents.pdf_processing_failed', document_id: pdf_document.id,
                                                                                                               error: 'Processing failed'))
        end
      end
    end

    context 'when document is nil' do
      it 'raises NoMethodError' do
        expect { described_class.perform_now(nil) }
          .to raise_error(NoMethodError)
      end
    end

    context 'when document has external link but no PDF file' do
      let(:web_document) { create(:captain_document, assistant: assistant, account: account, external_link: 'https://example.com') }

      it 'performs simple crawl when no firecrawl API key' do
        allow(InstallationConfig).to receive(:find_by).and_return(nil)
        job = described_class.new
        expect(job).to receive(:perform_simple_crawl).with(web_document)
        expect(job).not_to receive(:perform_pdf_processing)

        job.perform(web_document)
      end
    end
  end

  describe '#perform_pdf_processing' do
    let(:job_instance) { described_class.new }

    it 'creates PDF processing service with correct parameters' do
      pdf_processing_service = instance_double(Captain::Llm::PdfProcessingService)
      expect(Captain::Llm::PdfProcessingService).to receive(:new).with(pdf_document).and_return(pdf_processing_service)
      expect(pdf_processing_service).to receive(:process)

      job_instance.send(:perform_pdf_processing, pdf_document)
    end

    it 'marks document as available after processing' do
      pdf_processing_service = instance_double(Captain::Llm::PdfProcessingService)
      allow(Captain::Llm::PdfProcessingService).to receive(:new).with(pdf_document).and_return(pdf_processing_service)
      allow(pdf_processing_service).to receive(:process)

      expect { job_instance.send(:perform_pdf_processing, pdf_document) }
        .to change { pdf_document.reload.status }.to('available')
    end

    context 'when processing fails' do
      it 'logs error and re-raises' do
        pdf_processing_service = instance_double(Captain::Llm::PdfProcessingService)
        allow(Captain::Llm::PdfProcessingService).to receive(:new).with(pdf_document).and_return(pdf_processing_service)
        allow(pdf_processing_service).to receive(:process).and_raise(StandardError, 'Test error')

        allow(Rails.logger).to receive(:error)

        expect { job_instance.send(:perform_pdf_processing, pdf_document) }
          .to raise_error(StandardError, 'Test error')

        expect(Rails.logger).to have_received(:error).with(I18n.t('captain.documents.pdf_processing_failed', document_id: pdf_document.id,
                                                                                                             error: 'Test error'))
      end
    end
  end
end
