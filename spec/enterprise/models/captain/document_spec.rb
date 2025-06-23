require 'rails_helper'

RSpec.describe Captain::Document, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe 'document_type detection' do
    it 'detects PDF documents from URL' do
      document = assistant.documents.build(
        name: 'Test PDF',
        external_link: 'https://example.com/document.pdf'
      )
      
      document.save!
      
      expect(document.document_type).to eq('pdf')
      expect(document.pdf_document?).to be true
      expect(document.url_document?).to be false
    end

    it 'detects URL documents for non-PDF links' do
      document = assistant.documents.build(
        name: 'Test Page',
        external_link: 'https://example.com/page.html'
      )
      
      document.save!
      
      expect(document.document_type).to eq('url')
      expect(document.url_document?).to be true
      expect(document.pdf_document?).to be false
    end

    it 'defaults to URL for invalid URIs' do
      document = assistant.documents.build(
        name: 'Invalid URL',
        external_link: 'not-a-valid-url'
      )
      
      document.save!
      
      expect(document.document_type).to eq('url')
    end
  end

  describe 'job enqueueing' do
    it 'enqueues PDF processing job for PDF documents' do
      document = assistant.documents.build(
        name: 'Test PDF',
        external_link: 'https://example.com/document.pdf'
      )
      
      expect(Captain::Documents::PdfProcessingJob).to receive(:perform_later).with(document)
      
      document.save!
    end

    it 'enqueues crawl job for URL documents' do
      document = assistant.documents.build(
        name: 'Test Page',
        external_link: 'https://example.com/page.html'
      )
      
      expect(Captain::Documents::CrawlJob).to receive(:perform_later).with(document)
      
      document.save!
    end
  end
end