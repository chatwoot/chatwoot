require 'rails_helper'

RSpec.describe Captain::Tools::PdfProcessingService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) do
    assistant.documents.create!(
      name: 'Test PDF',
      external_link: 'https://example.com/test.pdf',
      document_type: :pdf
    )
  end

  subject { described_class.new(document) }

  describe '#process' do
    context 'when document is not a PDF' do
      before { allow(document).to receive(:pdf_document?).and_return(false) }

      it 'returns early without processing' do
        expect(subject.process).to be_nil
      end
    end

    context 'when document is a PDF' do
      let(:mock_file) { double('file', path: '/tmp/test.pdf', close: nil, unlink: nil) }
      let(:mock_batcher) { double('batcher') }
      let(:mock_vision) { double('vision') }

      before do
        allow(Down).to receive(:download).and_return(mock_file)
        allow(Dir).to receive(:mktmpdir).and_return('/tmp/pdf_images')
        allow(Dir).to receive(:glob).and_return(['/tmp/image1.png', '/tmp/image2.png'])
        allow(FileUtils).to receive(:rm_rf)
        
        allow(Captain::Tools::PdfPageBatcherService).to receive(:new).and_return(mock_batcher)
        allow(mock_batcher).to receive(:batch_pages).and_return(['/tmp/batched1.png'])
        
        allow(Captain::Tools::VisionTextExtractorService).to receive(:new).and_return(mock_vision)
        allow(mock_vision).to receive(:extract_text_from_multiple_images).and_return('Extracted text content')
      end

      it 'processes the PDF and updates document' do
        expect { subject.process }.to change { document.reload.status }.to('available')
      end

      it 'sets extracted content on the document' do
        subject.process
        expect(document.reload.content).to eq('Extracted text content')
      end

      it 'uses batching service for page processing' do
        expect(mock_batcher).to receive(:batch_pages).with(['/tmp/image1.png', '/tmp/image2.png'])
        subject.process
      end

      it 'uses Vision API for text extraction' do
        expect(mock_vision).to receive(:extract_text_from_multiple_images).with(['/tmp/batched1.png'])
        subject.process
      end
    end

    context 'when processing fails' do
      before do
        allow(Down).to receive(:download).and_raise(StandardError.new('Download failed'))
      end

      it 'logs error and updates document with error message' do
        expect(Rails.logger).to receive(:error).with(/PDF processing failed/)
        
        expect { subject.process }.to raise_error(StandardError)
        expect(document.reload.content).to include('Error processing PDF')
      end
    end
  end
end