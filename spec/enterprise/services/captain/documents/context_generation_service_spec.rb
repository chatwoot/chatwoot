require 'rails_helper'
require 'ostruct'

RSpec.describe Captain::Documents::ContextGenerationService do
  let(:chat) { instance_double(RubyLLM::Chat) }
  let(:response) { instance_double(RubyLLM::Message, content: "  Pricing page context.  \n") }

  before do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: 'test-key')
    InstallationConfig.where(name: %w[CAPTAIN_CONTEXT_GENERATION_MODEL CAPTAIN_OPEN_AI_MODEL]).delete_all

    allow(RubyLLM).to receive(:chat).and_return(chat)
    allow(chat).to receive(:with_temperature).and_return(chat)
    allow(chat).to receive(:with_instructions).and_return(chat)
    allow(chat).to receive(:ask).and_return(response)
  end

  describe '#generate' do
    it 'returns stripped context text from the model response' do
      service = described_class.new(
        document_content: 'Pricing docs for all plans',
        chunk_content: 'Business plan starts at $19/agent/month.',
        account_id: 1
      )

      result = service.generate

      expect(result).to eq('Pricing page context.')
    end

    it 'uses explicit model when provided' do
      service = described_class.new(
        document_content: 'Doc text',
        chunk_content: 'Chunk text',
        account_id: 1,
        model: 'gpt-4.1-mini'
      )

      expect(RubyLLM).to receive(:chat).with(model: 'gpt-4.1-mini').and_return(chat)

      service.generate
    end

    it 'uses CAPTAIN_CONTEXT_GENERATION_MODEL when configured' do
      create(:installation_config, name: 'CAPTAIN_CONTEXT_GENERATION_MODEL', value: 'gpt-4.1-mini')

      service = described_class.new(
        document_content: 'Doc text',
        chunk_content: 'Chunk text',
        account_id: 1
      )

      expect(RubyLLM).to receive(:chat).with(model: 'gpt-4.1-mini').and_return(chat)

      service.generate
    end

    it 'uses CAPTAIN_OPEN_AI_MODEL when context model is not configured' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4o-mini')

      service = described_class.new(
        document_content: 'Doc text',
        chunk_content: 'Chunk text',
        account_id: 1
      )

      expect(RubyLLM).to receive(:chat).with(model: 'gpt-4o-mini').and_return(chat)

      service.generate
    end

    it 'falls back to the service default model when no model config exists' do
      service = described_class.new(
        document_content: 'Doc text',
        chunk_content: 'Chunk text',
        account_id: 1
      )

      expect(RubyLLM).to receive(:chat).with(model: 'gpt-4.1').and_return(chat)

      service.generate
    end

    it 'returns empty string when chunk content is blank' do
      service = described_class.new(
        document_content: 'Doc text',
        chunk_content: '',
        account_id: 1
      )

      expect(service.generate).to eq('')
      expect(RubyLLM).not_to have_received(:chat)
    end

    it 'returns empty string when LLM call fails' do
      error = RubyLLM::Error.new(OpenStruct.new(body: {}), 'request failed')
      allow(chat).to receive(:ask).and_raise(error)

      service = described_class.new(
        document_content: 'Doc text',
        chunk_content: 'Chunk text',
        account_id: 1
      )

      expect(service.generate).to eq('')
    end
  end
end
