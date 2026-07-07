require 'rails_helper'

RSpec.describe Llm::BaseAiService do
  subject(:service) { described_class.new }

  let(:account) { create(:account) }

  before do
    InstallationConfig.where(name: %w[CAPTAIN_OPEN_AI_API_KEY CAPTAIN_OPEN_AI_MODEL]).destroy_all
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
  end

  describe '#initialize' do
    it 'uses the installation model when no feature is provided' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-nano')

      expect(described_class.new.model).to eq('gpt-4.1-nano')
    end

    it 'uses the account override when feature context is provided' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-nano')
      account.update!(captain_models: { 'assistant' => 'gpt-5.2' })

      expect(described_class.new(feature: 'assistant', account: account).model).to eq('gpt-5.2')
    end

    it 'uses the installation model when feature context has no account override' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-nano')

      expect(described_class.new(feature: 'assistant', account: account).model).to eq('gpt-4.1-nano')
    end

    it 'uses the feature default when feature context has no account override or installation model' do
      expect(described_class.new(feature: 'assistant', account: account).model).to eq(Llm::Models.default_model_for('assistant'))
    end
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
end
