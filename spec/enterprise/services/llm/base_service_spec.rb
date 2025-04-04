require 'rails_helper'

RSpec.describe Llm::BaseService do
  describe '#initialize' do
    let(:api_key) { 'test-key' }
    let(:model) { 'custom-model' }

    before do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: api_key)
    end

    it 'configures RubyLLM with the API key' do
      expect(RubyLLM).to receive(:configure) do |&block|
        config = OpenStruct.new
        block.call(config)
        expect(config.openai_api_key).to eq(api_key)
      end

      described_class.new
    end

    context 'when API key is missing' do
      before do
        InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY').destroy
      end

      it 'raises an error' do
        expect { described_class.new }.to raise_error(
          RuntimeError,
          /Failed to initialize LLM client: Couldn't find InstallationConfig/
        )
      end
    end

    context 'when model config exists' do
      before do
        create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: model)
      end

      it 'uses the configured model' do
        allow(RubyLLM).to receive(:configure)
        service = described_class.new
        expect(service.instance_variable_get(:@model)).to eq(model)
      end
    end

    context 'when model config is missing' do
      it 'uses the default model' do
        allow(RubyLLM).to receive(:configure)
        service = described_class.new
        expect(service.instance_variable_get(:@model)).to eq(described_class::DEFAULT_MODEL)
      end
    end
  end
end
