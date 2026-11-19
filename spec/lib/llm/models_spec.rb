# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::Models do
  describe '.providers' do
    it 'loads provider metadata from the config' do
      expect(described_class.providers).to include(
        'openai' => include('display_name' => 'OpenAI')
      )
    end
  end

  describe '.features' do
    it 'keeps every feature default in the allowed model list' do
      described_class.features.each do |feature_key, config|
        expect(config['models']).to include(config['default']), "#{feature_key} default model must be allowed"
      end
    end

    it 'references existing models from every feature' do
      described_class.features.each do |feature_key, config|
        missing_models = config['models'].reject { |model_name| described_class.models.key?(model_name) }

        expect(missing_models).to be_empty, "#{feature_key} references missing models: #{missing_models.join(', ')}"
      end
    end

    it 'routes each FAQ operation independently' do
      expect(described_class.default_model_for('document_faq_generation')).to eq('gpt-6-luna')
      expect(described_class.default_model_for('conversation_faq_generation')).to eq('gpt-5.2')
      expect(described_class.default_model_for('conversation_faq_matching')).to eq('gpt-6-luna')
    end

    it 'uses GPT-5.2 for Copilot workflows' do
      expect(described_class.default_model_for('copilot')).to eq('gpt-5.2')
      expect(described_class.default_model_for('copilot_workflows')).to eq('gpt-5.2')
      expect(described_class.features.dig('copilot_workflows', 'reasoning_effort')).to eq('none')
      expect(described_class.internal_feature?('copilot_workflows')).to be(true)
    end

    it 'offers only supported OpenAI models for conversation completion' do
      expect(described_class.models_for('conversation_completion')).to eq(
        %w[gpt-6-luna gpt-5.1 gpt-5.2]
      )
    end
  end

  describe '.models' do
    it 'references existing providers from every model' do
      missing_providers = described_class.models.filter_map do |model_name, config|
        provider = config['provider']
        next if described_class.providers.key?(provider)

        "#{model_name}: #{provider}"
      end

      expect(missing_providers).to be_empty
    end
  end

  describe '.models_for' do
    let(:haiku) { { 'id' => 'claude-haiku-5-5', 'display_name' => 'Claude Haiku 5.5', 'provider' => 'anthropic' } }

    before do
      allow(Llm::ProviderModels).to receive(:all).and_return([haiku])
    end

    it 'replaces curated Anthropic models with the listed ones for provider model features on self-hosted installations' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

      expect(described_class.models_for('editor')).to eq(%w[gpt-6-luna gpt-5.1 gpt-5.2 gemini-3-flash gemini-3-pro claude-haiku-5-5])
      expect(described_class.valid_model_for?('editor', 'claude-haiku-5-5')).to be(true)
      expect(described_class.feature_config('editor')[:models].last).to include(
        id: 'claude-haiku-5-5', display_name: 'Claude Haiku 5.5', provider: 'anthropic'
      )
    end

    it 'keeps features without provider models on the curated list' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

      expect(described_class.models_for('copilot')).to include('claude-sonnet-4.5')
      expect(described_class.valid_model_for?('copilot', 'claude-haiku-5-5')).to be(false)
    end

    it 'keeps Chatwoot Cloud on the curated list' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)

      expect(described_class.models_for('editor')).to include('claude-haiku-4.5')
      expect(described_class.models_for('editor')).not_to include('claude-haiku-5-5')
    end
  end

  describe '.temperature_for' do
    it 'passes the temperature through for a model missing from the bundled registry' do
      expect(described_class.temperature_for('claude-haiku-5-5', 0.3)).to eq(0.3)
    end
  end

  describe '.feature_config' do
    it 'returns model metadata for a feature' do
      config = described_class.feature_config('editor')

      expect(config[:default]).to eq('gpt-6-luna')
      expect(config[:models].first).to include(
        id: 'gpt-6-luna',
        display_name: 'GPT-6 Luna',
        provider: 'openai',
        credit_multiplier: 1
      )
    end
  end
end
