require 'rails_helper'

RSpec.describe Captain::Tools::DocumentationSearch do
  let(:tool) { described_class.new }
  let(:search_query) { 'how to configure inbox' }
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:embedding) { Array.new(1536) { rand(-1.0..1.0) } }
  let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }

  before do
    allow(Captain::Llm::UpdateEmbeddingJob).to receive(:perform_later)
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:get_embedding).with(search_query).and_return(embedding)
  end

  describe '#execute' do
    context 'when matching responses exist' do
      let!(:response) do
        create(:captain_assistant_response,
               assistant: assistant,
               account: account,
               question: 'How do I configure my inbox?',
               answer: 'Follow these steps...',
               status: :approved,
               embedding: embedding)
      end

      let!(:response_with_source) do
        document = create(:captain_document,
                          assistant: assistant,
                          account: account,
                          external_link: 'https://example.com/docs')
        create(:captain_assistant_response,
               assistant: assistant,
               account: account,
               question: 'What are inbox settings?',
               answer: 'Inbox settings include...',
               documentable: document,
               status: :approved,
               embedding: embedding)
      end

      it 'returns formatted responses' do
        result = tool.execute(search_query: search_query)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        # First response without source
        expect(result[0]).to include(
          question: response.question,
          answer: response.answer
        )
        expect(result[0]).not_to have_key(:source)

        # Second response with source
        expect(result[1]).to include(
          question: response_with_source.question,
          answer: response_with_source.answer,
          source: 'https://example.com/docs'
        )
      end
    end

    context 'when no matching responses exist' do
      it 'returns an empty array' do
        result = tool.execute(search_query: search_query)
        expect(result).to eq([])
      end
    end
  end

  describe '.description' do
    it 'has a description' do
      expect(described_class.description).to eq('Search through the documentation to find relevant answers')
    end
  end

  describe '.parameters' do
    it 'defines search_query parameter' do
      param = described_class.parameters[:search_query]
      expect(param).to be_a(RubyLLM::Parameter)
      expect(param.name).to eq(:search_query)
      expect(param.type).to eq(:string)
      expect(param.description).to eq('The search query to find relevant documentation')
      expect(param.required).to be true
    end
  end
end
