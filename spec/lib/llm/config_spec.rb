require 'rails_helper'

RSpec.describe Llm::Config do
  describe '.openai_api_base' do
    before { InstallationConfig.where(name: 'CAPTAIN_OPEN_AI_ENDPOINT').destroy_all }

    {
      nil => 'https://api.openai.com/v1',
      '' => 'https://api.openai.com/v1',
      'https://api.openai.com/' => 'https://api.openai.com/v1',
      'https://proxy.example.com' => 'https://proxy.example.com/v1',
      'https://openrouter.ai/api/' => 'https://openrouter.ai/api/v1',
      'https://openrouter.ai/api/v1' => 'https://openrouter.ai/api/v1',
      'https://openrouter.ai/api/v1/' => 'https://openrouter.ai/api/v1',
      'https://example.openai.azure.com/openai/v1' => 'https://example.openai.azure.com/openai/v1',
      'https://generativelanguage.googleapis.com/v1beta/openai/' => 'https://generativelanguage.googleapis.com/v1beta/openai',
      'https://gateway.ai.cloudflare.com/v1/account/gateway/openai' => 'https://gateway.ai.cloudflare.com/v1/account/gateway/openai',
      'https://v1.example.com' => 'https://v1.example.com/v1'
    }.each do |endpoint, expected|
      it "resolves #{endpoint.inspect} to #{expected}" do
        create(:installation_config, name: 'CAPTAIN_OPEN_AI_ENDPOINT', value: endpoint) unless endpoint.nil?

        expect(described_class.openai_api_base).to eq(expected)
      end
    end
  end

  describe '.chat_model_options' do
    before { InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'llama-3.3-70b-versatile') }

    it 'sends the installation model as-is when Chatwoot does not list it' do
      expect(described_class.chat_model_options('llama-3.3-70b-versatile'))
        .to eq(model: 'llama-3.3-70b-versatile', provider: :openai, assume_model_exists: true)
    end

    it 'keeps a listed model on the registry lookup' do
      expect(described_class.chat_model_options('gpt-6-luna')).to eq(model: 'gpt-6-luna')
    end

    it 'does not skip the lookup for an unlisted model that is not the installation model' do
      expect(described_class.chat_model_options('unknown-model')).to eq(model: 'unknown-model')
    end
  end

  describe '.configure_ruby_llm' do
    around do |example|
      original_base = RubyLLM.config.openai_api_base
      example.run
    ensure
      RubyLLM.configure { |config| config.openai_api_base = original_base }
    end

    it 'adds the API version to the configured OpenAI endpoint' do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://example.test/')

      described_class.send(:configure_ruby_llm)

      expect(RubyLLM.config.openai_api_base).to eq('https://example.test/v1')
    end

    it 'keeps an endpoint that already carries the API version' do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://openrouter.ai/api/v1/')

      described_class.send(:configure_ruby_llm)

      expect(RubyLLM.config.openai_api_base).to eq('https://openrouter.ai/api/v1')
    end
  end
end
