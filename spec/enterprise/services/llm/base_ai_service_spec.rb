require 'rails_helper'

RSpec.describe Llm::BaseAiService do
  subject(:service) { described_class.new }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
  end

  describe '#sanitize_json_response' do
    it 'strips ```json fences' do
      input = "```json\n{\"key\": \"value\"}\n```"
      expect(service.send(:sanitize_json_response, input)).to eq('{"key": "value"}')
    end

    it 'strips bare ``` fences' do
      input = "```\n{\"key\": \"value\"}\n```"
      expect(service.send(:sanitize_json_response, input)).to eq('{"key": "value"}')
    end

    it 'passes through plain JSON unchanged' do
      input = '{"key": "value"}'
      expect(service.send(:sanitize_json_response, input)).to eq('{"key": "value"}')
    end

    it 'returns nil for nil input' do
      expect(service.send(:sanitize_json_response, nil)).to be_nil
    end

    it 'strips surrounding whitespace' do
      input = "  \n{\"key\": \"value\"}\n  "
      expect(service.send(:sanitize_json_response, input)).to eq('{"key": "value"}')
    end
  end

  describe '#with_json_response_format' do
    let(:chat) { instance_double(RubyLLM::Chat) }

    it 'adds JSON response format for direct OpenAI' do
      allow(Llm::Config).to receive(:supports_structured_outputs_with_tools?).and_return(true)

      expect(chat).to receive(:with_params).with(response_format: { type: 'json_object' }).and_return(chat)

      expect(service.send(:with_json_response_format, chat)).to eq(chat)
    end

    it 'does not add params when structured outputs are unsupported and no safe params are present' do
      allow(Llm::Config).to receive(:supports_structured_outputs_with_tools?).and_return(false)

      expect(chat).not_to receive(:with_params)

      expect(service.send(:with_json_response_format, chat)).to eq(chat)
    end

    it 'keeps safe params when structured outputs are unsupported' do
      allow(Llm::Config).to receive(:supports_structured_outputs_with_tools?).and_return(false)

      expect(chat).to receive(:with_params).with(max_tokens: 1000).and_return(chat)

      expect(service.send(:with_json_response_format, chat, max_tokens: 1000)).to eq(chat)
    end
  end
end
