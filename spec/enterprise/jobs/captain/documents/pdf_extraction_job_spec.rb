require 'rails_helper'

RSpec.describe Captain::Documents::PdfExtractionJob, type: :job do
  let(:document) { create(:captain_document, external_link: 'https://example.com/document.pdf', source_type: 'pdf_upload') }
  let(:pdf_service) { instance_double(Captain::Tools::PdfExtractionService) }
  let(:pdf_content) do
    [
      { content: 'PDF page 1 content', page_number: 1, chunk_index: 1, total_chunks: 2 },
      { content: 'PDF page 2 content', page_number: 2, chunk_index: 2, total_chunks: 2 }
    ]
  end

  before do
    allow(Captain::Tools::PdfExtractionService)
      .to receive(:new)
      .and_return(pdf_service)
  end

  describe '#perform' do
    context 'when document is not a PDF' do
      let(:web_document) { create(:captain_document, external_link: 'https://example.com/page.html') }

      it 'returns early without processing' do
        expect(pdf_service).not_to receive(:perform)
        described_class.perform_now(web_document)
      end
    end

    context 'when document is a PDF' do
      it 'updates document status to in_progress' do
        allow(pdf_service).to receive(:perform).and_return({ success: true, content: pdf_content })
        allow(Captain::Tools::PdfExtractionParserJob).to receive(:perform_later)

        expect(document).to receive(:update).with(status: 'in_progress').once
        described_class.perform_now(document)
      end

      it 'uses correct PDF source for extraction' do
        allow(pdf_service).to receive(:perform).and_return({ success: true, content: pdf_content })
        allow(Captain::Tools::PdfExtractionParserJob).to receive(:perform_later)

        expect(Captain::Tools::PdfExtractionService)
          .to receive(:new)
          .with(document.external_link)

        described_class.perform_now(document)
      end

      context 'when document has attached file' do
        let(:attached_file) { instance_double(ActiveStorage::Attached::One, attached?: true) }

        before do
          allow(document).to receive(:file).and_return(attached_file)
        end

        it 'uses attached file for extraction' do
          allow(pdf_service).to receive(:perform).and_return({ success: true, content: pdf_content })
          allow(Captain::Tools::PdfExtractionParserJob).to receive(:perform_later)

          expect(Captain::Tools::PdfExtractionService)
            .to receive(:new)
            .with(document.file)

          described_class.perform_now(document)
        end
      end

      context 'when extraction succeeds' do
        before do
          allow(pdf_service).to receive(:perform).and_return({ success: true, content: pdf_content })
        end

        it 'updates document with first page content only' do
          expect(document).to receive(:update!).with(
            content: 'PDF page 1 content',
            status: 'available'
          )

          described_class.perform_now(document)
        end

        it 'resets previous responses once at the beginning' do
          allow(document).to receive(:update!)
          allow(Captain::Tools::PdfExtractionParserJob).to receive(:perform_later)

          expect(document.responses).to receive(:destroy_all).once

          described_class.perform_now(document)
        end

        it 'enqueues PdfExtractionParserJob for each content chunk' do
          allow(document).to receive(:update!)

          pdf_content.each do |chunk|
            expect(Captain::Tools::PdfExtractionParserJob)
              .to receive(:perform_later)
              .with(
                assistant_id: document.assistant_id,
                pdf_content: chunk,
                document_id: document.id
              )
          end

          described_class.perform_now(document)
        end

        it 'updates document status to in_progress initially' do
          allow(document).to receive(:update!)
          allow(Captain::Tools::PdfExtractionParserJob).to receive(:perform_later)

          expect(document).to receive(:update).with(status: 'in_progress').once
          described_class.perform_now(document)
        end

        it 'logs successful extraction' do
          allow(document).to receive(:update!)
          allow(Captain::Tools::PdfExtractionParserJob).to receive(:perform_later)

          expect(Rails.logger).to receive(:info).with(/PDF extraction successful/).at_least(:once)
          expect(Rails.logger).to receive(:info).with(/chunks queued/).at_least(:once)
          allow(Rails.logger).to receive(:info) # Allow other logging calls

          described_class.perform_now(document)
        end
      end

      context 'when extraction fails' do
        before do
          allow(pdf_service).to receive(:perform).and_return({
                                                               success: false,
                                                               errors: ['Invalid PDF format', 'File corrupted']
                                                             })
        end

        it 'updates document status to available' do
          expect(document).to receive(:update).with(status: 'in_progress')
          expect(document).not_to receive(:update).with(status: 'available')

          described_class.perform_now(document)
        end

        it 'logs the error' do
          expect(Rails.logger).not_to receive(:error)
          described_class.perform_now(document)
        end
      end

      context 'when extraction raises an exception' do
        before do
          allow(pdf_service).to receive(:perform).and_raise(Captain::Tools::PdfExtractionService::ExtractionError, 'Network error')
        end

        it 'updates document status to available' do
          expect(document).to receive(:update).with(status: 'in_progress')
          expect(document).not_to receive(:update).with(status: 'available')

          expect { described_class.perform_now(document) }.to raise_error(Captain::Tools::PdfExtractionService::ExtractionError)
        end

        it 'logs the exception' do
          allow(Rails.logger).to receive(:error)
          expect { described_class.perform_now(document) }.to raise_error(Captain::Tools::PdfExtractionService::ExtractionError)
        end
      end
    end
  end
end