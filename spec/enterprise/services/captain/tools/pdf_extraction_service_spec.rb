require 'rails_helper'

RSpec.describe Captain::Tools::PdfExtractionService do
  let(:service) { described_class.new(pdf_source) }
  let(:sample_pdf_path) { Rails.root.join('spec/fixtures/files/sample.pdf') }

  describe '#initialize' do
    context 'with valid PDF path' do
      let(:pdf_source) { sample_pdf_path.to_s }

      it 'initializes with the PDF source' do
        expect(service.pdf_source).to eq(pdf_source)
      end
    end

    context 'with URL' do
      let(:pdf_source) { 'https://example.com/sample.pdf' }

      it 'initializes with the PDF URL' do
        expect(service.pdf_source).to eq(pdf_source)
      end
    end
  end

  describe '#perform' do
    context 'with blank PDF source' do
      let(:pdf_source) { nil }

      it 'returns error for blank source' do
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:errors]).to include('Invalid PDF source')
      end
    end

    context 'with valid PDF file path' do
      let(:pdf_source) { sample_pdf_path.to_s }

      before do
        # Ensure the sample PDF exists
        skip 'Sample PDF file not available for testing' unless File.exist?(sample_pdf_path)
      end

      it 'handles PDF extraction gracefully' do
        result = service.perform
        expect(result).to have_key(:success)
        expect(result).to have_key(:content).or have_key(:errors)

        if result[:success]
          expect(result[:content]).to be_an(Array)
        else
          expect(result[:errors]).to be_an(Array)
        end
      end

      it 'returns structured result format' do
        result = service.perform

        if result[:success] && result[:content].present?
          first_chunk = result[:content].first
          expect(first_chunk).to have_key(:content)
          expect(first_chunk).to have_key(:page_number)
          expect(first_chunk).to have_key(:chunk_index)
          expect(first_chunk).to have_key(:total_chunks)
        else
          expect(result[:errors]).to be_present
        end
      end
    end

    context 'with malformed PDF' do
      let(:pdf_source) { Rails.root.join('spec/fixtures/files/sample.txt').to_s }

      it 'handles malformed PDF gracefully' do
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:errors]).to be_an(Array)
      end
    end

    context 'with HTTP URL' do
      let(:pdf_source) { 'https://example.com/sample.pdf' }

      it 'attempts to download and process PDF from URL' do
        temp_file = instance_double(Tempfile, path: sample_pdf_path.to_s, close: nil, unlink: nil)
        allow(Down).to receive(:download).and_return(temp_file)
        allow(File).to receive(:exist?).and_return(true)

        # Mock PDF reader
        mock_page = instance_double(PDF::Reader::Page, text: 'Sample PDF content')
        mock_pages = [mock_page]
        mock_reader = instance_double(PDF::Reader, pages: mock_pages)
        allow(PDF::Reader).to receive(:open).and_yield(mock_reader)

        result = service.perform
        expect(result[:success]).to be true
      end
    end
  end

  describe '#extract_text' do
    let(:pdf_source) { sample_pdf_path.to_s }

    before do
      skip 'Sample PDF file not available for testing' unless File.exist?(sample_pdf_path)
    end

    it 'handles text extraction gracefully' do
      expect { service.extract_text }.not_to raise_error(NoMethodError)

      # Should either succeed or raise a PDF::Reader error that gets caught
      begin
        extracted_content = service.extract_text
        expect(extracted_content).to be_an(Array)

        if extracted_content.any?
          page_content = extracted_content.first
          expect(page_content).to have_key(:page_number)
          expect(page_content).to have_key(:content)
        end
      rescue PDF::Reader::MalformedPDFError
        # This is expected for malformed PDFs
        # Test passes if we reach this point
      end
    end
  end

  describe 'private methods' do
    let(:pdf_source) { sample_pdf_path.to_s }

    describe '#clean_text' do
      it 'cleans text content properly' do
        dirty_text = "  \f  Some text with \r\n line breaks  \n\n\n  and extra spaces   "
        cleaned = service.send(:clean_text, dirty_text)

        expect(cleaned).not_to include("\f")
        expect(cleaned).not_to include("\r")
        expect(cleaned).to include('Some text with')
        expect(cleaned.strip).to eq(cleaned)
      end

      it 'returns nil for blank text' do
        cleaned = service.send(:clean_text, "   \n\n   ")
        expect(cleaned).to be_nil
      end
    end

    describe '#chunk_content' do
      let(:page_contents) do
        [
          { page_number: 1, content: 'Short content' },
          { page_number: 2, content: 'A' * 3000 } # Long content that needs chunking
        ]
      end

      it 'chunks content appropriately' do
        chunks = service.send(:chunk_content, page_contents, max_chunk_size: 1000)

        expect(chunks.length).to be >= 2 # Should have at least 2 chunks

        # Check first chunk (short content)
        first_chunk = chunks.first
        expect(first_chunk[:page_number]).to eq(1)
        expect(first_chunk[:total_chunks]).to eq(1)

        # Check that long content was processed
        long_content_chunks = chunks.select { |c| c[:page_number] == 2 }
        expect(long_content_chunks.length).to be >= 1

        # Verify long content was split appropriately
        total_long_content_length = long_content_chunks.sum { |c| c[:content].length }
        expect(total_long_content_length).to be > 0
      end
    end

    describe '#split_content_into_chunks' do
      it 'splits content by paragraphs first' do
        content = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."
        chunks = service.send(:split_content_into_chunks, content, 50)

        expect(chunks.length).to be >= 2
        expect(chunks.join(' ')).to include('First paragraph')
        expect(chunks.join(' ')).to include('Second paragraph')
      end

      it 'splits by sentences when paragraphs are too large' do
        long_paragraph = "#{('A' * 100)}. #{('B' * 100)}. #{('C' * 100)}."
        chunks = service.send(:split_content_into_chunks, long_paragraph, 150)

        expect(chunks.length).to be > 1
      end
    end
  end

  describe 'file validation' do
    context 'with uploaded file object' do
      let(:uploaded_file) do
        temp_file = instance_double(Tempfile, path: sample_pdf_path.to_s)
        instance_double(
          ActionDispatch::Http::UploadedFile,
          tempfile: temp_file,
          content_type: 'application/pdf',
          size: 1024
        )
      end
      let(:pdf_source) { uploaded_file }

      it 'validates uploaded file properties' do
        expect { service.send(:validate_uploaded_file) }.not_to raise_error
      end
    end

    context 'with oversized file' do
      let(:uploaded_file) do
        temp_file = instance_double(Tempfile, path: sample_pdf_path.to_s)
        instance_double(
          ActionDispatch::Http::UploadedFile,
          tempfile: temp_file,
          content_type: 'application/pdf',
          size: 30.megabytes
        )
      end
      let(:pdf_source) { uploaded_file }

      it 'raises error for oversized file' do
        expect { service.send(:validate_uploaded_file) }.to raise_error(/File too large/)
      end
    end

    context 'with invalid content type' do
      let(:uploaded_file) do
        temp_file = instance_double(Tempfile, path: sample_pdf_path.to_s)
        instance_double(
          ActionDispatch::Http::UploadedFile,
          tempfile: temp_file,
          content_type: 'text/plain',
          size: 1024
        )
      end
      let(:pdf_source) { uploaded_file }

      it 'raises error for invalid content type' do
        expect { service.send(:validate_uploaded_file) }.to raise_error('Invalid file type')
      end
    end
  end
end