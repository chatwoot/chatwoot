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
               documentable: document,
               status: 'approved')
      end

      before do
        allow(Resolv).to receive(:getaddresses).and_return(['93.184.216.34'])

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
        expect(result).not_to include('Citation index:')
      end

      it 'does not assign indexes to attachments or storage links' do
        assistant.update!(config: assistant.config.merge('feature_citation' => true))
        document.pdf_file.attach(
          io: StringIO.new('PDF content'),
          filename: 'private-file.pdf',
          content_type: 'application/pdf'
        )

        pdf_result = tool.perform(tool_context, query: 'private document')

        expect(pdf_result).not_to include('Citation index:')
        expect(tool_context.state[Captain::Assistant::CITATION_SOURCES_STATE_KEY]).to be_nil

        document.pdf_file.detach
        document.update!(external_link: 's3://private-bucket/password')

        storage_result = tool.perform(tool_context, query: 'private storage document')

        expect(storage_result).not_to include('Citation index:')
        expect(tool_context.state[Captain::Assistant::CITATION_SOURCES_STATE_KEY]).to be_nil

        document.update!(external_link: 'https://storage.example.com/private-file.pdf?token=secret')

        pdf_url_result = tool.perform(tool_context, query: 'private PDF URL')

        expect(pdf_url_result).not_to include('Citation index:')
        expect(tool_context.state[Captain::Assistant::CITATION_SOURCES_STATE_KEY]).to be_nil
      end

      it 'assigns stable numeric indexes to customer-visible document links' do
        assistant.update!(config: assistant.config.merge('feature_citation' => true))
        document.update!(external_link: 'https://help.example.com/password')

        result = tool.perform(tool_context, query: 'password')
        repeated_result = tool.perform(tool_context, query: 'password again')

        expect(result).to include('Citation index: 1')
        expect(repeated_result).to include('Citation index: 1')
        expect(result).not_to include('https://help.example.com/password')
        expect(result.scan('Citation index: 1').size).to eq(2)
        expect(result).not_to include('Citation index: 2')
        expect(tool_context.state[Captain::Assistant::CITATION_SOURCES_STATE_KEY]).to eq(1 => document.id)
      end

      it 'does not cite document URLs containing credentials' do
        assistant.update!(config: assistant.config.merge('feature_citation' => true))
        document.update!(external_link: 'https://user:pass@help.example.com/password')

        result = tool.perform(tool_context, query: 'password')

        expect(result).not_to include('Citation index:')
        expect(tool_context.state[Captain::Assistant::CITATION_SOURCES_STATE_KEY]).to be_nil
      end

      it 'logs tool usage for search' do
        expect(tool).to receive(:log_tool_usage).with('searching', { query: 'password reset' })
        expect(tool).to receive(:log_tool_usage).with('found_results', { query: 'password reset', count: 2 })

        tool.perform(tool_context, query: 'password reset')
      end

      it 'records retrieved faq ids and document ids into Chatwoot metadata' do
        tool.perform(tool_context, query: 'password reset')

        user = create(:user, account: account)
        user_faq = create(:captain_assistant_response, assistant: assistant, documentable: user, status: :approved)
        allow(Captain::AssistantResponse).to receive(:nearest_neighbors).and_return(
          Captain::AssistantResponse.where(id: user_faq.id)
        )
        tool.perform(tool_context, query: 'user faq')

        expect(tool_context.state.dig(:cw_metadata, :faq_ids)).to contain_exactly(response1.id, response2.id, user_faq.id)
        expect(tool_context.state.dig(:cw_metadata, :used_faq_ids)).to contain_exactly(user_faq.id)
        expect(tool_context.state.dig(:cw_metadata, :document_ids)).to contain_exactly(document.id)
      end

      it 'accumulates unique ids across multiple calls' do
        tool.perform(tool_context, query: 'password reset')
        tool.perform(tool_context, query: 'password reset again')

        expect(tool_context.state.dig(:cw_metadata, :faq_ids)).to contain_exactly(response1.id, response2.id)
        expect(tool_context.state.dig(:cw_metadata, :document_ids)).to contain_exactly(document.id)
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

      it 'leaves shared state untouched' do
        tool.perform(tool_context, query: 'nonexistent topic')

        expect(tool_context.state).to eq({})
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
