require 'rails_helper'

RSpec.describe Captain::Tools::FirecrawlParserJob, type: :job do
  describe '#perform' do
    let(:assistant) { create(:captain_assistant) }
    let(:payload) do
      {
        markdown: 'Launch Week I is here! 🚀',
        metadata: {
          'title' => 'Home - Firecrawl',
          'ogTitle' => 'Firecrawl',
          'url' => 'https://www.firecrawl.dev/'
        }
      }
    end

    it 'creates a new document when one does not exist' do
      expect do
        described_class.perform_now(assistant_id: assistant.id, payload: payload)
      end.to change(assistant.documents, :count).by(1)

      document = assistant.documents.last
      expect(document).to have_attributes(
        content: payload[:markdown],
        name: payload[:metadata]['title'],
        external_link: payload[:metadata]['url'],
        status: 'available'
      )
    end

    it 'updates existing document when one exists' do
      existing_document = create(:captain_document,
                                 assistant: assistant,
                                 account: assistant.account,
                                 external_link: payload[:metadata]['url'],
                                 content: 'old content',
                                 name: 'old title',
                                 status: :in_progress)

      expect do
        described_class.perform_now(assistant_id: assistant.id, payload: payload)
      end.not_to change(assistant.documents, :count)

      existing_document.reload
      expect(existing_document).to have_attributes(
        content: payload[:markdown],
        name: payload[:metadata]['title'],
        status: 'available'
      )
    end

    context 'when an error occurs' do
      it 'raises an error with a descriptive message' do
        allow(Captain::Assistant).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

        expect do
          described_class.perform_now(assistant_id: -1, payload: payload)
        end.to raise_error(/Failed to parse FireCrawl data/)
      end
    end
  end
end
