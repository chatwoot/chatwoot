require 'rails_helper'

RSpec.describe Captain::Tools::FaqLookupTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:tool_context) { Struct.new(:state).new({}) }

  before do
    # Create installation config for OpenAI API key to avoid errors
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')

    # Mock embedding service to avoid actual API calls
    embedding_service = instance_double(Captain::Llm::EmbeddingService)
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:get_embedding).and_return(Array.new(1536, 0.1))
  end

  describe '#description' do
    it 'returns the correct description' do
      expect(tool.description).to eq('Search FAQ responses using semantic similarity to find relevant answers')
    end
  end

  describe '#parameters' do
    it 'returns the correct parameters' do
      expect(tool.parameters).to have_key(:query)
      expect(tool.parameters[:query].name).to eq(:query)
      expect(tool.parameters[:query].type).to eq('string')
      expect(tool.parameters[:query].description).to eq('The question or topic to search for in the FAQ database')
    end
  end

  describe '#perform' do
    context 'when FAQs exist' do
      let(:document) { create(:captain_document, assistant: assistant) }
      let!(:response1) do
        create(:captain_assistant_response,
               assistant: assistant,
               question: 'How to reset password?',
               answer: 'Click on forgot password link',
               documentable: document,
               status: 'approved')
      end
      let!(:response2) do
        create(:captain_assistant_response,
               assistant: assistant,
               question: 'How to change email?',
               answer: 'Go to settings and update email',
               status: 'approved')
      end

      before do
        # Mock nearest_neighbors to return our test responses
        allow(Captain::AssistantResponse).to receive(:nearest_neighbors).and_return(
          Captain::AssistantResponse.where(id: [response1.id, response2.id])
        )
      end

      it 'searches FAQs and returns formatted responses' do
        result = tool.perform(tool_context, query: 'password reset')

        expect(result).to include('Question: How to reset password?')
        expect(result).to include('Answer: Click on forgot password link')
        expect(result).to include('Question: How to change email?')
        expect(result).to include('Answer: Go to settings and update email')
      end

      it 'includes source link when document has external_link' do
        document.update!(external_link: 'https://help.example.com/password')

        result = tool.perform(tool_context, query: 'password')

        expect(result).to include('Source: https://help.example.com/password')
      end

      it 'logs tool usage for search' do
        expect(tool).to receive(:log_tool_usage).with('searching', { query: 'password reset' })
        expect(tool).to receive(:log_tool_usage).with('found_results', { query: 'password reset', count: 2 })

        tool.perform(tool_context, query: 'password reset')
      end
    end

    context 'when no FAQs found' do
      before do
        # Return empty result set
        allow(Captain::AssistantResponse).to receive(:nearest_neighbors).and_return(Captain::AssistantResponse.none)
      end

      it 'returns no results message' do
        result = tool.perform(tool_context, query: 'nonexistent topic')
        expect(result).to eq('No relevant FAQs found for: nonexistent topic')
      end

      it 'logs tool usage for no results' do
        expect(tool).to receive(:log_tool_usage).with('searching', { query: 'nonexistent topic' })
        expect(tool).to receive(:log_tool_usage).with('no_results', { query: 'nonexistent topic' })

        tool.perform(tool_context, query: 'nonexistent topic')
      end
    end

    context 'with blank query' do
      it 'handles empty query' do
        # Return empty result set
        allow(Captain::AssistantResponse).to receive(:nearest_neighbors).and_return(Captain::AssistantResponse.none)

        result = tool.perform(tool_context, query: '')
        expect(result).to eq('No relevant FAQs found for: ')
      end
    end
  end

  describe '#active?' do
    it 'returns true for public tools' do
      expect(tool.active?).to be true
    end
  end
end
