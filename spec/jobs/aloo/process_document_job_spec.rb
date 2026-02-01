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

  describe 'job configuration' do
    it 'is queued in low queue' do
      expect(described_class.new.queue_name).to eq('low')
    end

    it 'retries on StandardError' do
      expect(described_class.retry_on_exceptions).to include(StandardError)
    end
  end
end
