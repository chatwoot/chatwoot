# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::FeatureRouter do
  let(:account) { create(:account) }

  describe '.resolve' do
    before do
      allow(ChatwootApp).to receive(:self_hosted_paid?).and_return(false)
    end

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

    it 'uses a valid account model override for an internal feature' do
      account.update!(captain_models: { 'conversation_completion' => 'gpt-5.2' })

      resolved = described_class.resolve(feature: 'conversation_completion', account: account)

      expect(resolved).to include(
        feature: 'conversation_completion',
        provider: 'openai',
        model: 'gpt-5.2',
        source: :account_override
      )
    end

    it 'uses the installation model for conversation completion on paid self-hosted installations' do
      allow(ChatwootApp).to receive(:self_hosted_paid?).and_return(true)
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5.1')

      resolved = described_class.resolve(feature: 'conversation_completion', account: account)

      expect(resolved).to eq(
        feature: 'conversation_completion',
        provider: 'openai',
        model: 'gpt-5.1',
        source: :installation_override
      )
    end

    it 'keeps the OpenAI provider for a custom installation model' do
      allow(ChatwootApp).to receive(:self_hosted_paid?).and_return(true)
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'custom-openai-model')

      resolved = described_class.resolve(feature: 'conversation_completion', account: account)

      expect(resolved).to include(
        provider: 'openai',
        model: 'custom-openai-model',
        source: :installation_override
      )
    end

    it 'keeps account overrides ahead of the installation model' do
      allow(ChatwootApp).to receive(:self_hosted_paid?).and_return(true)
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5.1')
      account.update!(captain_models: { 'conversation_completion' => 'gpt-5.2' })

      resolved = described_class.resolve(feature: 'conversation_completion', account: account)

      expect(resolved).to include(
        model: 'gpt-5.2',
        source: :account_override
      )
    end

    context 'with a custom endpoint on a self-hosted installation' do
      before do
        InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://api.groq.com/openai/v1')
        InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'llama-3.3-70b-versatile')
      end

      %w[editor label_suggestion].each do |feature|
        it "uses the installation model for #{feature}" do
          resolved = described_class.resolve(feature: feature, account: account)

          expect(resolved).to eq(
            feature: feature,
            provider: 'openai',
            model: 'llama-3.3-70b-versatile',
            source: :installation_override
          )
        end
      end

      it 'keeps account overrides ahead of the installation model' do
        account.update!(captain_models: { 'editor' => 'gpt-4.1' })

        resolved = described_class.resolve(feature: 'editor', account: account)

        expect(resolved).to include(model: 'gpt-4.1', source: :account_override)
      end

      it 'keeps the feature default on Chatwoot Cloud' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)

        resolved = described_class.resolve(feature: 'editor', account: account)

        expect(resolved).to include(model: 'gpt-4.1-mini', source: :default)
      end

      it 'does not extend the installation model to other features' do
        resolved = described_class.resolve(feature: 'assistant', account: account)

        expect(resolved[:source]).to eq(:default)
      end
    end

    it 'keeps the editor default when no custom endpoint is configured' do
      InstallationConfig.where(name: 'CAPTAIN_OPEN_AI_ENDPOINT').destroy_all
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5.1')

      resolved = described_class.resolve(feature: 'editor', account: account)

      expect(resolved).to include(model: 'gpt-4.1-mini', source: :default)
    end

    it 'resolves GPT-5.2 as the assistant default when Captain V2 is enabled without storing an account override' do
      account.enable_features!('captain_integration')

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
      account.enable_features!('captain_integration')
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
