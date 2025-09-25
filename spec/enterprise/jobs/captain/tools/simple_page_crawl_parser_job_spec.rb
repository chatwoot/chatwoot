require 'rails_helper'

RSpec.describe Captain::Tools::SimplePageCrawlParserJob, type: :job do
  describe '#perform' do
    let(:assistant) { create(:captain_assistant) }
    let(:page_link) { 'https://example.com/page' }
    let(:page_title) { 'Example Page Title' }
    let(:content) { 'Some page content here' }
    let(:crawler) { instance_double(Captain::Tools::SimplePageCrawlService) }

    before do
      allow(Captain::Tools::SimplePageCrawlService).to receive(:new)
        .with(page_link)
        .and_return(crawler)

      allow(crawler).to receive(:page_title).and_return(page_title)
      allow(crawler).to receive(:body_text_content).and_return(content)
    end

    context 'when the page is successfully crawled' do
      it 'creates a new document if one does not exist' do
        expect do
          described_class.perform_now(assistant_id: assistant.id, page_link: page_link)
        end.to change(assistant.documents, :count).by(1)

        document = assistant.documents.last
        expect(document.external_link).to eq(page_link)
        expect(document.name).to eq(page_title)
        expect(document.content).to eq(content)
        expect(document.status).to eq('available')
      end

      it 'updates existing document if one exists' do
        existing_document = create(:captain_document,
                                   assistant: assistant,
                                   external_link: page_link,
                                   name: 'Old Title',
                                   content: 'Old content')

        expect do
          described_class.perform_now(assistant_id: assistant.id, page_link: page_link)
        end.not_to change(assistant.documents, :count)

        existing_document.reload
        expect(existing_document.name).to eq(page_title)
        expect(existing_document.content).to eq(content)
        expect(existing_document.status).to eq('available')
      end

      context 'when title or content exceed maximum length' do
        let(:long_title) { 'x' * 300 }
        let(:long_content) { 'x' * 20_000 }

        before do
          allow(crawler).to receive(:page_title).and_return(long_title)
          allow(crawler).to receive(:body_text_content).and_return(long_content)
        end

        it 'truncates the title and content' do
          described_class.perform_now(assistant_id: assistant.id, page_link: page_link)

          document = assistant.documents.last
          expect(document.name.length).to eq(255)
          expect(document.content.length).to eq(15_000)
        end
      end
    end

    context 'when the crawler fails' do
      before do
        allow(crawler).to receive(:page_title).and_raise(StandardError.new('Failed to fetch'))
      end

      it 'raises an error with the page link' do
        expect do
          described_class.perform_now(assistant_id: assistant.id, page_link: page_link)
        end.to raise_error("Failed to parse data: #{page_link} Failed to fetch")
      end
    end

    context 'when title and content are nil' do
      before do
        allow(crawler).to receive(:page_title).and_return(nil)
        allow(crawler).to receive(:body_text_content).and_return(nil)
      end

      it 'creates document with empty strings and updates the status to available' do
        described_class.perform_now(assistant_id: assistant.id, page_link: page_link)

        document = assistant.documents.last
        expect(document.name).to eq('')
        expect(document.content).to eq('')
        expect(document.status).to eq('available')
      end
    end
  end
end
