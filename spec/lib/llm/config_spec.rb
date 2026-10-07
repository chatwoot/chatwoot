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

  describe 'global RubyLLM configuration' do
    around do |example|
      original_base = RubyLLM.config.openai_api_base
      example.run
    ensure
      described_class.reset!
      RubyLLM.configure { |config| config.openai_api_base = original_base }
    end

    it 'adds the version segment a bare endpoint is missing' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_ENDPOINT', value: 'https://proxy.example.com')
      described_class.reset!
      described_class.initialize!

      expect(RubyLLM.config.openai_api_base).to eq('https://proxy.example.com/v1')
    end

    it 'keeps an endpoint that already carries the version segment' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_ENDPOINT', value: 'https://openrouter.ai/api/v1/')
      described_class.reset!
      described_class.initialize!

      expect(RubyLLM.config.openai_api_base).to eq('https://openrouter.ai/api/v1')
    end
  end
end
