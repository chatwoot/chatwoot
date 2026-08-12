# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::FeatureRouter do
  let(:account) { create(:account) }

  describe '.resolve' do
    it 'returns the feature default without an account' do
      resolved = described_class.resolve(feature: 'editor')

      expect(resolved).to eq(
        feature: 'editor',
        provider: 'openai',
        model: 'gpt-4.1-mini',
        source: :default
      )
    end

    it 'uses a valid account model override' do
      account.update!(captain_models: { 'editor' => 'gpt-4.1' })

      resolved = described_class.resolve(feature: 'editor', account: account)

      expect(resolved).to include(
        feature: 'editor',
        provider: 'openai',
        model: 'gpt-4.1',
        source: :account_override
      )
    end

    it 'resolves GPT-5.2 as the assistant default when Captain V2 is enabled without storing an account override' do
      account.enable_features!('captain_integration_v2')

      resolved = described_class.resolve(feature: 'assistant', account: account)

      expect(resolved).to include(
        feature: 'assistant',
        provider: 'openai',
        model: 'gpt-5.2',
        source: :default
      )
      expect(account.reload.captain_models).to be_nil
    end

    it 'keeps account model overrides ahead of the Captain V2 default' do
      account.enable_features!('captain_integration_v2')
      account.update!(captain_models: { 'assistant' => 'gpt-5.1' })

      resolved = described_class.resolve(feature: 'assistant', account: account)

      expect(resolved).to include(
        model: 'gpt-5.1',
        source: :account_override
      )
    end

    it 'falls back to the feature default when the account override is invalid' do
      account.captain_models = { 'editor' => 'invalid-model' }

      resolved = described_class.resolve(feature: 'editor', account: account)

      expect(resolved).to include(
        model: 'gpt-4.1-mini',
        source: :default
      )
    end

    it 'falls back to the feature default when the account override is blank' do
      account.update!(captain_models: { 'editor' => '' })

      resolved = described_class.resolve(feature: 'editor', account: account)

      expect(resolved).to include(
        model: 'gpt-4.1-mini',
        source: :default
      )
    end

    it 'raises for unknown features' do
      expect { described_class.resolve(feature: 'unknown_feature') }
        .to raise_error(described_class::UnknownFeatureError, 'Unknown LLM feature: unknown_feature')
    end
  end
end
