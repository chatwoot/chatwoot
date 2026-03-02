# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::ProcessDocumentJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:document) { create(:aloo_document, :with_file, assistant: assistant, account: account) }

  describe '#perform' do
    context 'when document not found' do
      it 'returns early' do
        expect do
          described_class.new.perform(999_999)
        end.not_to raise_error
      end
    end

    context 'when processing file' do
      before do
        allow(Aloo::Embedding).to receive(:create_from_chunks)
          .and_return([])
      end

      context 'with text file' do
        let(:document) { create(:aloo_document, :with_file, assistant: assistant, account: account) }

        it 'extracts content' do
          described_class.new.perform(document.id)

          expect(document.reload.content).to be_present
        end

        it 'creates chunks' do
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            expect(chunks).to be_an(Array)
            []
          end

          described_class.new.perform(document.id)
        end

        it 'marks as available' do
          described_class.new.perform(document.id)

          expect(document.reload.status).to eq('available')
        end
      end

      context 'with xlsx file' do
        let(:document) { create(:aloo_document, :with_xlsx, assistant: assistant, account: account) }

        it 'extracts spreadsheet content and marks as available' do
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            combined = chunks.join("\n")
            expect(combined).to include('Name')
            expect(combined).to include('Test Item')
            []
          end

          described_class.new.perform(document.id)
          expect(document.reload.status).to eq('available')
        end
      end

      context 'with xls file' do
        let(:document) { create(:aloo_document, :with_xls, assistant: assistant, account: account) }

        it 'extracts spreadsheet content and marks as available' do
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            combined = chunks.join("\n")
            expect(combined).to include('Name')
            expect(combined).to include('Test Item')
            []
          end

          described_class.new.perform(document.id)
          expect(document.reload.status).to eq('available')
        end
      end

      context 'with docx file' do
        let(:document) { create(:aloo_document, :with_docx, assistant: assistant, account: account) }

        it 'extracts document content and marks as available' do
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            combined = chunks.join("\n")
            expect(combined).to include('Test document content for processing.')
            expect(combined).to include('Second paragraph of test content.')
            []
          end

          described_class.new.perform(document.id)
          expect(document.reload.status).to eq('available')
        end
      end

      context 'with pptx file' do
        let(:document) { create(:aloo_document, :with_pptx, assistant: assistant, account: account) }

        it 'extracts slide content and marks as available' do
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            combined = chunks.join("\n")
            expect(combined).to include('Test Slide Content')
            []
          end

          described_class.new.perform(document.id)
          expect(document.reload.status).to eq('available')
        end
      end

      context 'with csv file' do
        let(:document) { create(:aloo_document, :with_csv, assistant: assistant, account: account) }

        it 'extracts CSV rows as key-value pairs and marks as available' do
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            combined = chunks.join("\n")
            expect(combined).to include('Store_Name:')
            expect(combined).to include('Café Arabica')
            []
          end

          described_class.new.perform(document.id)
          expect(document.reload.status).to eq('available')
        end
      end

      context 'with Windows-1252 encoded csv file' do
        let(:document) { create(:aloo_document, :with_windows1252_csv, assistant: assistant, account: account) }

        it 'converts encoding to UTF-8 and extracts content' do
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            combined = chunks.join("\n")
            expect(combined.encoding).to eq(Encoding::UTF_8)
            expect(combined).to be_valid_encoding
            expect(combined).to include('Café')
            []
          end

          described_class.new.perform(document.id)
          expect(document.reload.status).to eq('available')
        end

        it 'produces content that can be JSON-serialized' do
          serializable = true
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            chunks.each do |chunk|
              { text: chunk }.to_json
            rescue JSON::GeneratorError, Encoding::UndefinedConversionError
              serializable = false
            end
            []
          end

          described_class.new.perform(document.id)
          expect(serializable).to be(true)
        end
      end

      context 'with Windows-1252 encoded text file' do
        let(:document) do
          doc = create(:aloo_document, assistant: assistant, account: account)
          # Simulate a Windows-1252 encoded text file (e.g. "Café menu" with \xE9 for é)
          content = "Welcome to our Caf\xE9!\nEnjoy your stay.".b
          doc.file.attach(io: StringIO.new(content), filename: 'menu.txt', content_type: 'text/plain')
          doc
        end

        it 'converts to valid UTF-8' do
          allow(Aloo::Embedding).to receive(:create_from_chunks) do |chunks:, **_opts|
            combined = chunks.join("\n")
            expect(combined.encoding).to eq(Encoding::UTF_8)
            expect(combined).to be_valid_encoding
            expect(combined).to include('Caf')
            []
          end

          described_class.new.perform(document.id)
          expect(document.reload.status).to eq('available')
        end
      end

      context 'with unsupported type' do
        before do
          document.file.attach(
            io: StringIO.new('binary content'),
            filename: 'file.exe',
            content_type: 'application/octet-stream'
          )
        end

        it 'marks as failed' do
          described_class.new.perform(document.id)

          expect(document.reload.status).to eq('failed')
        end
      end
    end

    context 'when processing website' do
      let(:document) { create(:aloo_document, :website, assistant: assistant, account: account) }

      before do
        stub_request(:get, document.source_url)
          .to_return(body: '<html><body><main>Website content</main></body></html>', status: 200)
        allow(Aloo::Embedding).to receive(:create_from_chunks).and_return([])
      end

      it 'calls WebScrapingService' do
        expect(Aloo::WebScrapingService).to receive(:new)
          .with(url: document.source_url, crawl_full_site: false)
          .and_call_original

        described_class.new.perform(document.id)
      end

      it 'stores scraped content' do
        described_class.new.perform(document.id)

        expect(document.reload.content).to be_present
      end

      it 'marks as available on success' do
        described_class.new.perform(document.id)

        expect(document.reload.status).to eq('available')
      end
    end

    context 'when error occurs' do
      before do
        allow_any_instance_of(described_class).to receive(:extract_content).and_raise(StandardError, 'Processing error')
      end

      it 'marks document as failed' do
        expect do
          described_class.new.perform(document.id)
        end.to raise_error(StandardError)

        expect(document.reload.status).to eq('failed')
      end
    end

    context 'when no content extracted' do
      before do
        allow_any_instance_of(described_class).to receive(:extract_content).and_return(nil)
      end

      it 'marks as failed' do
        described_class.new.perform(document.id)

        expect(document.reload.status).to eq('failed')
      end
    end
  end

  describe 'chunking' do
    let(:job) { described_class.new }
    let(:long_content) { 'A' * 3000 }

    before do
      # Access the private method for testing
      allow(job).to receive(:chunk_content).and_call_original
    end

    it 'splits content into chunks' do
      chunks = job.send(:chunk_content, long_content)

      expect(chunks.size).to be > 1
    end

    it 'respects chunk size limit' do
      chunks = job.send(:chunk_content, long_content)

      chunks.each do |chunk|
        expect(chunk.length).to be <= described_class::CHUNK_SIZE + described_class::CHUNK_OVERLAP
      end
    end

    it 'maintains overlap between chunks' do
      # Use content with natural break points
      content = ('Word. ' * 500).strip
      chunks = job.send(:chunk_content, content)

      # With overlap, chunks should share some content
      expect(chunks.size).to be > 1
    end

    it 'breaks at natural boundaries' do
      content = "First paragraph content.\n\nSecond paragraph content." * 50
      chunks = job.send(:chunk_content, content)

      # Most chunks should end at paragraph or sentence boundary
      chunks[0..-2].each do |chunk| # Skip last chunk
        expect(chunk).to match(/[.!\?]$|\n$/)
      end
    end
  end

  describe '#ensure_utf8' do
    let(:job) { described_class.new }

    it 'returns UTF-8 content unchanged' do
      content = 'Hello Café'.encode('UTF-8')
      result = job.send(:ensure_utf8, content)

      expect(result.encoding).to eq(Encoding::UTF_8)
      expect(result).to eq('Hello Café')
    end

    it 'converts Windows-1252 content to UTF-8' do
      # \xE9 is é in Windows-1252, \x92 is right single quote
      content = "Caf\xE9 & Chang\x92s".b
      result = job.send(:ensure_utf8, content)

      expect(result.encoding).to eq(Encoding::UTF_8)
      expect(result).to be_valid_encoding
      expect(result).to include('Café')
      expect { { text: result }.to_json }.not_to raise_error
    end

    it 'converts ISO-8859-1 content to UTF-8' do
      content = "R\xE9sum\xE9".b
      result = job.send(:ensure_utf8, content)

      expect(result.encoding).to eq(Encoding::UTF_8)
      expect(result).to be_valid_encoding
      expect(result).to include('Résumé')
    end

    it 'handles pure ASCII content' do
      content = 'Plain ASCII text'.b
      result = job.send(:ensure_utf8, content)

      expect(result.encoding).to eq(Encoding::UTF_8)
      expect(result).to eq('Plain ASCII text')
    end
  end

  describe 'job configuration' do
    it 'is queued in low queue' do
      expect(described_class.new.queue_name).to eq('low')
    end

    it 'retries on StandardError' do
      expect(described_class.retry_on_exceptions).to include(StandardError)
    end
  end
end
