require 'rails_helper'

RSpec.describe Captain::AssistantResponse, type: :model do
  describe '.search' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:portal) { create(:portal, account: account, slug: 'customer-help') }
    let(:article) { create(:article, account: account, portal: portal, status: :archived) }

    it 'excludes unavailable Help Center sources without widening the original result set' do
      archived_document = create(
        :captain_document,
        assistant: assistant,
        external_link: "https://help.chatwoot.test/hc/#{portal.slug}/articles/#{article.slug}"
      )
      archived_response = create(:captain_assistant_response, assistant: assistant, documentable: archived_document)
      external_document = create(:captain_document, assistant: assistant, external_link: 'https://example.com/docs')
      available_responses = create_list(
        :captain_assistant_response,
        4,
        assistant: assistant,
        documentable: external_document
      )
      lower_ranked_response = create(:captain_assistant_response, assistant: assistant, documentable: external_document)
      candidate_ids = [archived_response.id, *available_responses.map(&:id), lower_ranked_response.id]
      candidates = described_class.where(id: candidate_ids).in_order_of(:id, candidate_ids)
      embedding_service = instance_double(Captain::Llm::EmbeddingService, get_embedding: Array.new(1536, 0.1))

      allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
      allow(described_class).to receive(:nearest_neighbors).and_return(candidates)

      with_modified_env HELPCENTER_URL: 'https://help.chatwoot.test' do
        expect(described_class.search('shipping')).to eq(available_responses)
      end
    end
  end

  describe 'account validation' do
    it 'uses the assistant account when the account is not set' do
      assistant = create(:captain_assistant)
      assistant_response = build(:captain_assistant_response, assistant: assistant, account: nil)

      expect(assistant_response).to be_valid
      expect(assistant_response.account).to eq(assistant.account)
    end

    it 'rejects an assistant from another account' do
      account = create(:account)
      assistant_response = build(:captain_assistant_response, account: account)

      expect(assistant_response).not_to be_valid
      expect(assistant_response.errors[:assistant]).to include('is invalid')
    end
  end
end
