# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::FeatureRouter do
  let(:account) { create(:account) }

  describe '.resolve' do
    it 'returns the single configured model as the feature default without an account' do
      resolved = described_class.resolve(feature: 'editor')

      expect(resolved).to include(
        feature: 'editor',
        model: Llm::Config.model,
        source: :default
      )
    end

    it 'ignores account model overrides and returns single source model' do
      account.update!(captain_models: { 'editor' => 'gpt-4.1' })

      resolved = described_class.resolve(feature: 'editor', account: account)

      expect(resolved).to include(
        feature: 'editor',
        model: Llm::Config.model,
        source: :default
      )
    end

    it 'resolves the single configured model for V2 accounts' do
      account.enable_features!('captain_integration_v2')

      resolved = described_class.resolve(feature: 'assistant', account: account)

      expect(resolved).to include(
        feature: 'assistant',
        model: Llm::Config.model,
        source: :default
      )
      expect(account.reload.captain_models).to be_nil
    end

    it 'raises for unknown features' do
      expect { described_class.resolve(feature: 'unknown_feature') }
        .to raise_error(described_class::UnknownFeatureError, 'Unknown LLM feature: unknown_feature')
    end
  end
end
